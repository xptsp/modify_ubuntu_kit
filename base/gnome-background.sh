#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Replaces default Ubuntu background with Red Dragon background..."
	echo ""
	exit 0
fi

#==============================================================================
_title "Replacing default Ubuntu background with Red Dragon background..."
#==============================================================================
cd /usr/share/backgrounds
mv warty-final-ubuntu.png warty-final-ubuntu-original.png
cp ${MUK_DIR}/files/red_dragon.png /usr/share/backgrounds/
ln -sf red_dragon.png warty-final-ubuntu.png
