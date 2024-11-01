#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs GitHub Desktop for Linux on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing GitHub Desktop for Linux..."
#==============================================================================
# First: Install the software:
wget -qO - https://mirror.mwt.me/shiftkey-desktop/gpgkey | gpg --dearmor | tee /usr/share/keyrings/mwt-desktop.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/mwt-desktop.gpg] https://mirror.mwt.me/shiftkey-desktop/deb/ any main" > /etc/apt/sources.list.d/mwt-desktop.list
apt update
apt install -y github-desktop
