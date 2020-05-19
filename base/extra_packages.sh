#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs some extra packages on your machine."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing some extra packages on your machine..."
#==============================================================================
apt install -y dh-modaliases build-essential linux-headers-generic dkms dpkg-dev debhelper checkinstall ttf-ubuntu-font-family
apt install -y p7zip-full p7zip-rar rar unrar net-tools rename tree squashfs-tools git genisoimage
cc ${MUK_DIR}/files/usbreset.c -o /usr/local/bin/usbreset
