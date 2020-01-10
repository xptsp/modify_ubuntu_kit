#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Creates development workspace after boot."
	echo ""
	exit 0
fi

#==============================================================================
_title "Adding script to creates development workspace after boot...."
#==============================================================================
if [[ ! -z "${CHROOT}" ]]; then
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/13_workspace.sh /usr/local/finisher/tasks.d/13_workspace.sh
else
	${MUK_DIR}/files/tasks.d/13_workspace.sh
fi
