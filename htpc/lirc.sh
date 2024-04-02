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

# Second: Add the Ubuntu 16.04 repository and keys:
#==============================================================================
echo "deb http://ca.archive.ubuntu.com/ubuntu/ xenial universe" > /etc/apt/sources.list.d/xenial.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 40976EAF437D05B5
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3B4FE6ACC0B21F32

# Third: Pin the necessary packages so that they are pulled instead of the default ones:
#==============================================================================
cat << EOF > /etc/apt/preferences.d/lirc
Package: lirc*
Pin: release v=16.04
Pin-Priority: 1100

Package: liblircclient0
Pin: release v=16.04
Pin-Priority: 1100
EOF

# Fourth: Install the LIRC packages from the Ubuntu xenial repository:
#==============================================================================
apt update
apt install -y lirc

# Fifth: Add finisher task to configure "LIRC":
#==============================================================================
add_taskd 50_lirc.sh
