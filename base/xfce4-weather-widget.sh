#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs updated XFCE weather widget."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing updated XFCE Weather widget..."
#==============================================================================
wget http://mxrepo.com/mx/repo/pool/main/x/xfce4-weather-plugin/xfce4-weather-plugin_0.10.2-1%7Emx17_amd64.deb -O /tmp/xfce4-weather-plugin.deb
apt install -y /tmp/xfce4-weather-plugin.deb
rm /tmp/xfce4-weather-plugin.deb

