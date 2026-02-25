#!/bin/bash

# --- HARDENED CONFIGURATION ---
INTERFACE="ens18"
GATEWAY="192.168.1.1"
DNS_SERVERS="[1.1.1.1, 8.8.8.8]" # Quad9 or Cloudflare preferred for stability
SUMMARY_FILE="summary_config"
# -----------------------------

# Parse Parameters
STATIC_IP=""
for arg in "$@"; do
    case $arg in
        sip=*)
        STATIC_IP="${arg#*=}"
        ;;
    esac
done

echo "--------------------------------------------------"
echo "Hardened VM Customization Tool"
echo "--------------------------------------------------"

# 1. State Capture
OLD_IP=$(ip addr show "$INTERFACE" | awk '/inet / {print $2}' | cut -d'/' -f1)
OLD_UUID=$(cat /etc/machine-id)

# 2. Machine ID Regeneration
echo "[*] Cleaning machine-id and DUID..."
sudo rm -f /etc/machine-id /var/lib/dbus/machine-id
sudo dbus-uuidgen --ensure=/etc/machine-id
sudo dbus-uuidgen --ensure
NEW_UUID=$(cat /etc/machine-id)

# 3. Generating Hardened Netplan
# link-local: [] disables IPv6 auto-config
# dhcp4-overrides: stops DHCP from pushing unwanted routes/DNS
if [ -n "$STATIC_IP" ]; then
    echo "[*] Mode: HARDENED STATIC ($STATIC_IP)"
    [[ "$STATIC_IP" != */* ]] && STATIC_IP="$STATIC_IP/24"
    
    sudo bash -c "cat <<EOF > /etc/netplan/00-installer-config.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      link-local: [ ]
      dhcp4: no
      dhcp6: no
      accept-ra: no
      addresses:
        - $STATIC_IP
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: $DNS_SERVERS
EOF"
else
    echo "[*] Mode: HARDENED DHCP"
    sudo bash -c "cat <<EOF > /etc/netplan/00-installer-config.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      link-local: [ ]
      dhcp4: yes
      dhcp6: no
      accept-ra: no
      dhcp4-overrides:
        use-dns: true
        use-routes: true
EOF"
fi

# 4. Clean and Apply
echo "[*] Applying network lock..."
sudo rm -f /var/lib/dhcp/dhclient.* /var/lib/NetworkManager/dhclient.* 2>/dev/null
sudo netplan apply

# 5. Update Summary
if [ -f /etc/update-motd.d/50-landscape-sysinfo ]; then
    sudo /etc/update-motd.d/50-landscape-sysinfo > /dev/null 2>&1
fi

# 6. Final Logging
NEW_IP=$(ip addr show "$INTERFACE" | awk '/inet / {print $2}' | cut -d'/' -f1)
{
    echo "Date: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "Mode: $([ -n "$STATIC_IP" ] && echo "Static" || echo "DHCP")"
    echo "IP: $OLD_IP -> $NEW_IP"
    echo "UUID: $OLD_UUID -> $NEW_UUID"
    echo "--------------------------------------------------"
} >> "$SUMMARY_FILE"

echo "[+] Hardened IP is now: $NEW_IP"
read -p "Finalize with reboot? (y/n): " answer
[[ "$answer" =~ ^[Yy]$ ]] && sudo reboot
