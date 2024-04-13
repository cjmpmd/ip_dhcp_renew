# DHCP new IP request
## Ubuntu VM UID renewal

### Warning:

> [!CAUTION]
> Warning: this will require the DHCPd to dynamically assign a new IPv4 at reboot, this will cause connectivity issues if executed via remote (ssh).


> [!NOTE]
>### Context
>When launching a new VM from a cloned template, the IP assigned by the DHCP will conflict with an existing VM (if cloned more than once).
>This created an IP conflict within the network, after troubleshooting the netplan and network configuration, the error was raised from the UUID in /etc/machine-id.

>This script automates the creation of a new random ID, updates the /etc/machine-id and the bus files, logs the previous IP and machine-id and reboots the system.

> [!NOTE]
>### Justification:
>1. **Streamlining:** Within the context of cloud automation, I encountered the UUID conflict and after troubleshooting, I created the script to optimize the VM cloning and launching.
>2. **Practice:** While currently reviewing topics regarding cloud automation, for the sake of on-hands practice I decided to create this repo

>### Notes:
>- VM OS: Ubuntu 22.04.04 lts
>- The script needs to be granted privileges to execute.
>- The script was previously created and now uploaded as a repo for easy access and sharing.

### Future improvements:
- [x] Initial commit! :tada:
- [ ] Add nested shell scripts, this to prevent IP reassingning by mistake.
- [ ] Add user and password; and remove the user from the clone
- [ ] Dynamically retrieve the new IP address (?)
### ChangeLog:
- Initial commit

