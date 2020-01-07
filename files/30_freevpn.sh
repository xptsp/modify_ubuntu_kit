#!/bin/bash
adduser --disabled-password htpc < /dev/null
passwd -d htpc
usermod -aG htpc ${USERNAME}
usermod -aG ${USERNAME},adm,cdrom,dip,lpadmin,plugdev,sambashare,pulse,pulse-access,dialout htpc
sed -i "s|9999|$(id -u htpc)|g" /etc/iptables/rules.v4

# Change the ethernet adapter name in our Split Tunnel VPN routing:
if [[ -z "${ETH_NAME}" ]]; then
    ETHERNET=$(lshw -c network -disable usb -short | grep -i "ethernet")
    IFS=" " read -ra ETH_ARR <<< $ETHERNET
    unset IFS
    export ETH_NAME=${ETH_ARR[1]}
fi
[[ ! -z "${ETH_NAME}" ]] && sed -i "s|enp0s3|${ETH_NAME}|g" /etc/sysctl.d/9999-vpn.conf

# Create Samba entries:
cat << DONE >> /etc/samba/smb.conf

[htpc]
comment=HTPC home folder
path=/home/htpc
browseable=Yes
writeable=Yes
only guest=no
create mask=0777
directory mask=0777
public=no
DONE

# Create Samba password for user "htpc"
(echo ${PASSWORD:-"xubuntu"}; echo ${PASSWORD:-"xubuntu"}) | smbpasswd -a htpc
