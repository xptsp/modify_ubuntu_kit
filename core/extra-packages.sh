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
source /etc/os-release
[[ "${VERSION_ID/\./}" -lt 2204 ]] && apt install -y ttf-ubuntu-font-family
apt install -y p7zip-full p7zip-rar rar unrar net-tools rename tree squashfs-tools git genisoimage dialog unionfs-fuse
