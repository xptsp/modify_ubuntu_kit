#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Google Chrome and WhatsApp on your computer."
	echo ""
	exit 0
fi

# Make sure Google Chrome is installed, as WhatsApp requires it:
#==============================================================================
PROG=$(whereis google-chrome | cut -d" " -f 2)
[[ -z "${PROG}" ]] && ${MUK_DIR}/programs/chrome.sh

#==============================================================================
_title "Installing  WhatsApp..."
#==============================================================================
wget https://www.thefanclub.co.za/sites/default/files/public/downloads/whatsapp-webapp_1.0_all.deb -O /tmp/whatsapp-webapp_1.0_all.deb
apt install -y /tmp/whatsapp-webapp_1.0_all.deb
rm /tmp/whatsapp-webapp_1.0_all.deb
