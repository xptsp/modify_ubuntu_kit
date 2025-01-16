#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs ScreenCopy (scrcpy) and ScreenCopy GUI (scrcpy-gui) on your computer."
	echo ""
	exit 0
fi

if [[ ${OS_VER} -lt 2004 ]]; then echo -e "${RED}ERROR:${NC} Ubuntu versions below 20.04 not supported!"; exit 1; fi 

#==============================================================================
_title "Install ScrCpy for Ubuntu..."
#==============================================================================
test -f /etc/apt/sources.list.d/xptsp_ppa.list || ${MUK_DIR}/base/custom-xptsp.sh
apt install scrcpy

#==============================================================================
_title "Install ScrCpy GUI for Ubuntu..."
#==============================================================================
VER=1.5.1
wget https://github.com/Tomotoes/scrcpy-gui/releases/download/${VER}/ScrcpyGui-${VER}.deb -O /tmp/ScrcpyGui.deb
apt install -y /tmp/ScrcpyGui.deb
rm /tmp/ScrcpyGui.deb
