#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs XFCE4 Terminal, replacing GNome Terminal (if installed)."
	echo ""
	exit 0
fi

#==============================================================================
_title "Removing Gnome Terminal..."
#==============================================================================
apt purge -y gnome-terminal

#==============================================================================
_title "Installing XFCE4 Terminal..."
#==============================================================================
apt install -y xfce4-terminal
sed -i "s|Exec=xfce4-terminal|Exec=xfce4-terminal --maximize|" /usr/share/applications/xfce4-terminal.desktop
