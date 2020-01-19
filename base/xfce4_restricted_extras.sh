#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Ubuntu Restricted Extras on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Ubuntu restricted extras..."
#==============================================================================
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula boolean true" | debconf-set-selections
apt install -y ubuntu-restricted-extras

#==============================================================================
_title "Installing and Building the DVD decoder..."
#==============================================================================
apt-get install -y libdvd-pkg
dpkg-reconfigure -f noninteractive libdvd-pkg
apt-mark hold libdvd-pkg libdvdcss2
