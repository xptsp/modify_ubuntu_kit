#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Removing XFCE packages not required for a HTPC machine"
	echo ""
	exit 0
fi

#==============================================================================
_title "Removing packages not required for a HTPC machine:"
#==============================================================================
apt purge -y --autoremove xfce4-utils xfce4-dict* xfce4-notes* xfce4-screenshooter* xfce4-session xfce4-panel xfce4-terminal xfce4-taskmanager
apt purge -y --autoremove xfconf xfburn* xfwm4 xfdesktop4 thunar* exo-utils thunderbird* engrampa* puzzles* evince*
apt purge -y --autoremove catfish* gigolo* gnome-mines* gnome-sudoku* libreoffice-* python3-uno* mugshot* onboard* atril*
apt purge -y --autoremove onboard-data* orage* parole* pidgin* pidgin-libnotify* python3-uno* ristretto* simple-scan* zathura 
apt purge -y --autoremove cups-daemon thunar-dropbox-plugin mate-calc* printer-driver* system-config*
apt purge -y --autoremove remarkable
apt purge -y --autoremove github-desktop
[ -f ~/.config/Trolltech.conf ] && rm ~/.config/Trolltech.conf
[ -d ~/.config/libreoffice ] && rm -R ~/.config/libreoffice
