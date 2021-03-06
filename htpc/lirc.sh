#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs LIRC on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing LIRC..."
#==============================================================================
# First: Attempt to set up the LIRC package:
#==============================================================================
echo "lirc lirc/dev_input_device select /dev/lirc0" | debconf-set-selections
echo "lirc lirc/transmitter select None" | debconf-set-selections
echo "lirc lirc/serialport select /dev/ttyS0" | debconf-set-selections
echo "lirc lirc/remote select Windows Media Center Transceivers/Remotes (all)" | debconf-set-selections

# Second: Add the xenial repo, install the package, then remove the repo:
#==============================================================================
if [[ $OS_VER -gt 1604 ]]; then
	echo "deb http://ca.archive.ubuntu.com/ubuntu/ xenial universe" > /etc/apt/sources.list.d/xenial.list
	apt update
	apt install -y lirc/xenial
	apt-mark hold lirc
	rm /etc/apt/sources.list.d/xenial.list
	apt update
else
	apt install lirc
fi

# Third: Add finisher task to configure "LIRC":
#==============================================================================
add_taskd 50_lirc.sh
