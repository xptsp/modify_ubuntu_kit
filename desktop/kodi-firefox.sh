#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Mozilla Firefox addon for Kodi on your computer."
	echo ""
	exit 0
fi

# First: Install the Kodi addon:
#==============================================================================
### First: Get the repo:
git clone --depth=1 https://github.com/xptsp/script.kodi.launches.firefox ${KODI_OPT}/script.kodi.launches.firefox
### Second: Link the repo:
ln -sf ${KODI_OPT}/script.kodi.launches.firefox ${KODI_ADD}/script.kodi.launches.firefox
### Third: Enable addon by default:
kodi_enable script.kodi.launches.firefox
