#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Imitation DOS commands on your computer."
	echo ""
	exit 0
fi

#==============================================================================
<<<<<<< HEAD
_title "Marking OS as base..."
=======
_title "Marking OS as desktop..."
>>>>>>> parent of b63ed14... Okay, you got me....
#==============================================================================
echo "desktop" > /usr/local/finisher/build.txt
