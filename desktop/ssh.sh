#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs SSH on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing and configuring SSH..."
#==============================================================================
# First: Install the software (duh :p)
#==============================================================================
apt install -y ssh

# Third: Configure as appropriate:
#==============================================================================
ischroot && (systemctl disable ssh; rm -v /etc/ssh/ssh_host_*)
add_taskd 12_ssh.sh
