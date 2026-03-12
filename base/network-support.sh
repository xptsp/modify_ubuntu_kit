#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs support for NFS and CIFS mounts."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing support for NFS and CIFS mounts...."
#==============================================================================
apt install -y nfs-common cifs-utils

# Second: Add task to the finisher script:
add_bootd 11_remote_mods.sh
