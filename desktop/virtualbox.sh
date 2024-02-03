#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs VirtualBox and extension pack on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install VirtualBox..."
#==============================================================================
apt-get install -y debconf-utils

# Set the debconf selection
echo virtualbox-ext-pack virtualbox-ext-pack/license select true | debconf-set-selections
apt install -y virtualbox virtualbox-ext-pack virtualbox-guest-additions-iso
