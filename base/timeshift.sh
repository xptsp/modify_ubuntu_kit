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
wget https://github.com/teejee2008/timeshift/releases/download/v20.11.1/timeshift_20.11.1_amd64.deb -O /tmp/timeshift_20.11.1_amd64.deb
apt install -y /tmp/timeshift_20.11.1_amd64.deb
rm /tmp/timeshift_20.11.1_amd64.deb

# Second: Add the finisher script:
#==============================================================================
add_taskd 70_timeshift.sh
