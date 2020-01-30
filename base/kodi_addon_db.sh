#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Preps the install for additional Kodi addons."
	echo ""
	exit 0
fi

#==============================================================================
_title "Prepping the install for additional Kodi addons..."
#==============================================================================
[[ ! -d /usr/share/kodi/userdata/addon_data ]] && mkdir -p /usr/share/kodi/userdata/addon_data
7z x ${MUK_DIR}/files/kodi_addon_db.7z -O/usr/share/kodi/userdata/addon_data
