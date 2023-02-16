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
[[ "$(cat /etc/os-release | grep "VERSION_ID=" | cut -d"\"" -f 2 | cut -d" " -f 1)" != "22.04" ]] && apt install -y ttf-ubuntu-font-family
apt install -y dh-modaliases build-essential dkms dpkg-dev debhelper checkinstall
apt install -y p7zip-full p7zip-rar rar unrar net-tools rename tree squashfs-tools git genisoimage dialog
cc ${MUK_DIR}/files/usbreset.c -o /usr/local/bin/usbreset
