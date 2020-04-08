#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Unified Remote on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install Unified Remote..."
#==============================================================================
# First: Download and install the software:
#==============================================================================
wget https://www.unifiedremote.com/download/linux-x64-deb -O /tmp/urserver.deb
apt install -y /tmp/urserver.deb
rm /tmp/urserver.deb

# Second: Adding Unified Remote systemd service:
#==============================================================================
ln -sf ${MUK_DIR}/files/urserver.service /etc/systemd/system/urserver.service
systemctl enable urserver
ischroot || systemctl start urserver
