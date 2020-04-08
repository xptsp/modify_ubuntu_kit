#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Steam on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Steam..."
#==============================================================================
### First: Install the software (duh :p)
#==============================================================================
dpkg --add-architecture i386
apt update
apt install -y steam

### Second: Pull the "script.kodi.launches.emulationstation" addon:
#==============================================================================
git clone --depth=1 https://github.com/BrosMakingSoftware/Kodi-Launches-Steam-Addon ${KODI_OPT}/Kodi-Launches-Steam-Addon
ln -sf ${KODI_OPT}/Kodi-Launches-Steam-Addon/script.kodi.launches.steam ${KODI_ADD}/script.kodi.launches.steam
kodi_enable script.kodi.launches.steam