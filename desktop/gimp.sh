#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs GIMP on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing GIMP..."
#==============================================================================
add-apt-repository -y ppa:otto-kesselgulasch/gimp
FILE=/etc/apt/sources.list.d/otto-kesselgulasch-ubuntu-gimp-impish.list
test -e $FILE && sed -i "s| impish | focal | g" $FILE && sed -i "s| jammy | focal | g" $FILE
apt install -y gimp
