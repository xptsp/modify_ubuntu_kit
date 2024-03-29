#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs and configures Samba on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install and configure Samba"
#==============================================================================
# First: Install the packages:
#==============================================================================
apt install -y samba cifs-utils smbclient winbind $([[ "$OS_VER" -lt 2004 ]] && echo system-config-samba)

# Second: Create a GKSU replacement script:
#==============================================================================
cat << EOF > /usr/local/bin/gksu
#!/bin/bash
pkexec env DISPLAY=\$DISPLAY XAUTHORITY=\$XAUTHORITY \$@
EOF
chown root:root /usr/local/bin/gksu
chmod +x /usr/local/bin/gksu
touch /etc/libuser.conf

# Third: Configure Samba for user 1000 (whoever that is):
#==============================================================================
sed -i 's/#   wins support = .*/   wins support = yes/g' /etc/samba/smb.conf
sed -i 's/\[global\]/[global]\n   security = user\n   min protocol = SMB2/g' /etc/samba/smb.conf
cat << EOF >> /etc/samba/smb.conf

[kodi]
comment="kodi" home folder
path=/home/kodi
browseable=Yes
writeable=Yes
only guest=no
create mask=0777
directory mask=0777
public=no
EOF
change_username /etc/samba/smb.conf

# Fourth: Add Samba finisher task:
#==============================================================================
add_taskd 50_samba.sh
AO=$(ischroot && echo "disable" || echo "restart")
systemctl ${AO} smbd
systemctl ${AO} nmbd
