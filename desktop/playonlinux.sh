#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs WINE on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Wine..."
#==============================================================================
dpkg --add-architecture i386
apt update
apt install -y software-properties-common
wget -qO- https://dl.winehq.org/wine-builds/winehq.key | apt-key add -
LSB=$(lsb_release -cs)
echo "deb http://dl.winehq.org/wine-builds/ubuntu/ ${LSB} main" > /etc/apt/sources.list.d/wine-${LSB}.list
echo "# deb-src http://dl.winehq.org/wine-builds/ubuntu/ ${LSB} main" >> /etc/apt/sources.list.d/wine-${LSB}.list
apt update
apt install -y --install-recommends wine-stable

#==============================================================================
_title "Installing PlayOnLinux..."
#==============================================================================
wget -q "http://deb.playonlinux.com/public.gpg" -O- | sudo apt-key add -
echo "deb http://deb.playonlinux.com/ ${LSB} main" > /etc/apt/sources.list/playonlinux-${LSB}.list
sudo apt-get update
sudo apt-get install -y playonlinux
