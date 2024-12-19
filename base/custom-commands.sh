#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs imitation DOS commands and custom scripts on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Creating imitation DOS commands..."
#==============================================================================
DST=/usr/local/bin
ln -sf /usr/bin/clear ${DST}/cls

#==============================================================================
_title "Getting other custom scripts..."
#==============================================================================
FILE=/usr/local/bin/peanut
wget https://github.com/xptsp/openwrt-peanut/raw/refs/heads/main/files/peanut -O ${FILE}
chmod +x ${FILE} 
