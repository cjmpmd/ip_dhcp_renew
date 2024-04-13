
#Notes:
#WHy
# Need to grant privileges (if not granted yet) to execute
# Warning: this will promp the DHCPd to dynamically assign a new IPv4 at reboot, 
# this will cause connectivity issues if executed via remote (ssh).

# Command to retrieve the current IPv4 address (replace eth0 with your interface name)
ipv4_address=$(ip addr show ens18 | awk '/inet / {print $2}' | cut -d'/' -f1)

# Specify the file path where you want to append the IPv4 address
file_path="summary_config"

# Retrieving the conflicting machine id
input_file="/etc/machine-id"
UUID_conflict=$(cat "$input_file")

# Removing the conflicting machine id from etc and dbus
sudo rm -f /etc/machine-id
sudo rm /var/lib/dbus/machine-id

# Generate new random machine id
# etc and dbus replication
sudo dbus-uuidgen --ensure=/etc/machine-id
sudo dbus-uuidgen --ensure

# Newly created machine id and storing in a variable
UUID_NO_conflict=$(cat "$input_file")

############################ USER FEEDBACK ############################

# Feedback and Summary logging
echo "$(date +'%Y-%m-%d %H:%M:%S')" >> "$file_path"
echo "Previous IP: $ipv4_address" >> "$file_path"
echo "Previous UUID: $UUID_conflict" >> "$file_path"
echo "New      UUID: $UUID_NO_conflict" >> "$file_path"
"--------------------------------------------------" >> "$file_path"

# Function to prompt user for system rebootconfirmation
prompt_reboot() {
    echo "The IP reconfiguration is completed!"
    echo ""
    echo "Don't forget to copy this IP:"
    echo "$ipv4_address"
    echo ""
    read -p "Would you like to reboot to apply changes? (yes/no)" answer
#    read -p "Do you want to reboot the system? (yes/no): " answer
    case "$answer" in
        [Yy]|[Yy][Ee][Ss])
            echo "Rebooting the system..."
#            sudo reboot
            ;;
        [Nn]|[Nn][Oo])

            echo "Reboot cancelled. Exiting."
            echo "The changes will be applied in the next system reboot."
            echo "Some configuration conflicts may arise until the system is rebooted."
            ;;
        *)
            echo "Invalid response. Please enter 'yes' or 'no'."
            prompt_reboot  # Prompt again recursively
            ;;
    esac
}

# Prompt user for reboot confirmation
prompt_reboot