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
_title "Marking OS as docker..."
#==============================================================================
FILE=/usr/local/finisher/build.txt
cp /etc/os-release ${FILE}
echo "MUK_BUILD=\"docker\"" >> ${FILE}