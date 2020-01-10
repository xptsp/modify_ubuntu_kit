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
apt remove -y --purge --autoremove catfish* gigolo* gnome-mines* gnome-sudoku* libreoffice-* python3-uno* mugshot* onboard* atril*
apt remove -y --purge --autoremove onboard-data* orage* parole* pidgin* pidgin-libnotify* python3-uno* ristretto* simple-scan* zathura 
apt remove -y --purge --autoremove thunderbird* xfburn*  xfce4-dict* xfce4-notes* xfce4-screenshooter* engrampa* puzzles* evince* 
apt remove -y --purge --autoremove cups-daemon thunar-dropbox-plugin
[ -f ~/.config/Trolltech.conf ] && rm ~/.config/Trolltech.conf
[ -d ~/.config/libreoffice ] && rm -R ~/.config/libreoffice
