#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs cross-compilation tools on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install Compilation Tools..."
#==============================================================================
apt install -y dh-modaliases build-essential dkms dpkg-dev debhelper checkinstall meson

#==============================================================================
_title "Install Cross-Compilation Tools..."
#==============================================================================
apt install -y gcc-arm-linux-gnueabihf libc6-armhf-cross u-boot-tools bc make gcc libc6-dev libncurses5-dev libssl-dev bison flex swig python3-dev ccache
apt install -y qemu-user-static debootstrap binfmt-support
