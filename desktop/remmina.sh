#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Remmina on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Remmina...."
#==============================================================================
# First: Install Remmina:
#==============================================================================
apt-add-repository -y --no-update ppa:remmina-ppa-team/remmina-next
apt update
apt install -y remmina remmina-plugin-rdp remmina-plugin-secret remmina-plugin-spice

# Second: Pull the "script.kodi.launches.emulationstation" addon:
#==============================================================================
### First: Get the repo:
git clone --depth=1 https://github.com/xptsp/script.kodi.launches.remmina ${KODI_OPT}/script.kodi.launches.remmina
### Second: Link the repo:
ln -sf ${KODI_OPT}/script.kodi.launches.remmina ${KODI_ADD}/script.kodi.launches.remmina
### Third: Enable addon by default:
kodi_enable script.kodi.launches.remmina
