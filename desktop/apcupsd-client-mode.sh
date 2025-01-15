#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Install and Configure APCUPSD as network client"
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing APCUPSD..."
#==============================================================================
# First: Install the software:
#==============================================================================
apt install -y apcupsd

#==============================================================================
# Second: Configure the software:
#==============================================================================
FILE=/etc/apcupsd/apcupsd.conf
test -f ${FILE}.bak || sudo cp ${FILE} ${FILE}.bak
sed -i "s|^UPSCABLE .*|UPSCABLE ether|" ${FILE}
sed -i "s|^UPSTYPE .*|UPSTYPE net|" ${FILE}
sed -i "s|^DEVICE .*|DEVICE $(ip route | grep default | awk '{print $3}')|" ${FILE}
sed -i "s|^POLLTIME .*|POLLTIME 10|" ${FILE}
sed -i "s|^BATTERYLEVEL .*|BATTERYLEVEL 10|" ${FILE}
sed -i "s|^MINUTES .*|MINUTES 15|" ${FILE}
sed -i "s|^NETSERVER .*|NETSERVER on|" ${FILE}
sed -i "s|^NISIP .*|NISIP 0.0.0.0|" ${FILE}
sed -i "s|^NISPORT .*|NISPORT 3551|" ${FILE}

#==============================================================================
# Third: Enable and restart the service:
#==============================================================================
sed -i "s|^ISCONFIGURED=.*|ISCONFIGURED=yes|" /etc/default/apcupsd
systemctl restart apcupsd

#==============================================================================
# Fourth: Fix the broadcast message issue:
#==============================================================================
sed -i "s|^WALL=.*|WALL=logger|" /etc/apcupsd/apccontrol

#==============================================================================
_title "Adding hibernation script to APCUPS script directory..."
#==============================================================================
FILE=/usr/local/bin/hibernate
cat << EOF > ${FILE}
#!/bin/bash
# Hibernate the system - designed to be called via symlink from /etc/apcupsd
# directory in case of apcupsd initiating a shutdown/reboot.  Can also be used
# interactively or from any script to cause a hibernate.

# Do the hibernate.  Assuming successful hibernation: On resume, tell controlling script 
# (/etc/apcupsd/apccontrol) NOT to continue with default action (i.e. shutdown).
/usr/bin/systemctl hibernate && exit 99

# At this point, it is assumed that hibernation failed.  Resume the apccontrol script:
exit 0
EOF
chmod +x ${FILE}
ln -s ${FILE} /etc/apcupsd/doshutdown
