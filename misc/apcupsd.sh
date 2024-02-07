#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Install and Configure APCUPSD."
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

#==============================================================================
# Third: Enable and restart the service:
#==============================================================================
sed -i "s|^ISCONFIGURED=.*|ISCONFIGURED=yes|" /etc/default/apcupsd
systemctl restart apcupsd

#==============================================================================
# Fourth: Fix the broadcast message issue:
#==============================================================================
sed -i "s|^WALL=.*|WALL=logger|" /etc/apcupsd/apccontrol
