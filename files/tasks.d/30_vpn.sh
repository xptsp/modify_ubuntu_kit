#!/bin/bash

# Add user "vpn" to user 1000 group, and user 1000 to "vpn" group:
usermod -aG vpn ${USERNAME}
usermod -aG ${USERNAME} vpn

# Edit the defauilt rules to restrict user "vpn" from all internet access:
# NOTE: Rule is removed once a VPN tunnel with appropriate scripts is connected.
sed -i "s|9999|$(id -u vpn)|g" /etc/iptables/rules.v4

# Change the ethernet adapter name in our Split Tunnel VPN routing:
[[ -z "${ETH_NAME}" ]] && ETH_NAME=($(lshw -c network -disable usb -short | grep -i "ethernet" | awk '{print $2}'))
[[ ! -z "${ETH_NAME[0]}" ]] && sed -i "s|enp0s3|${ETH_NAME[0]}|g" /etc/sysctl.d/9999-vpn.conf

# Create Samba entries:
test -f /etc/samba/smb.conf && cat << DONE >> /etc/samba/smb.conf

[vpn]
comment=VPN home folder
path=/home/vpn
browseable=Yes
writeable=Yes
only guest=no
create mask=0777
directory mask=0777
public=no
DONE

# Create Samba password for user "vpn"
[[ -z "${PASSWORD}" ]] && PASSWORD=$(grep grep "^ID=" /etc/os-release | cut -d= -f 2)
(echo ${PASSWORD}; echo ${PASSWORD}) | smbpasswd -a vpn
