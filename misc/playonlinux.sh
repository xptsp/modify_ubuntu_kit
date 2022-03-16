#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs PlayOnLinux on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing PlayOnLinux..."
#==============================================================================
if [[ "$OS_VER" -lt 2004 ]]; then
	LSB=$(lsb_release -cs)
	wget -q "http://deb.playonlinux.com/public.gpg" -O- | sudo apt-key add -
	echo "deb http://deb.playonlinux.com/ ${LSB} main" > /etc/apt/sources.list.d/playonlinux-${LSB}.list
	apt-get update
fi
apt-get install -y playonlinux
