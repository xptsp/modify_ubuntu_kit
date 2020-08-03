#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs TimeShift on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing TimeShift..."
#==============================================================================
# First: Install the software :p
#==============================================================================
[[ "$OS_VER" -lt 2004 ]] && apt-add-repository -y ppa:teejee2008/ppa
apt install -y timeshift

# Second: Add the finisher script:
#==============================================================================
add_taskd 70_timeshift.sh
