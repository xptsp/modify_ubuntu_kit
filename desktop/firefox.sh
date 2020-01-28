#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Mozilla Firefox on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Mozilla Firefox..."
#==============================================================================
# First: Install the software:
#==============================================================================
apt install -y firefox

# Second: Install the Kodi addon:
#==============================================================================
KODI_OPT=${KODI_OPT:-"/opt/kodi"}
KODI_ADD=${KODI_ADD:-"/etc/skel/.kodi/addons"}
### First: Get the repo:
[[ ! -d ${KODI_OPT} ]] && mkdir -p ${KODI_OPT}
git clone --depth=1 https://github.com/xptsp/script.kodi.launches.firefox ${KODI_OPT}/script.kodi.launches.firefox
### Second: Link the repo:
[[ ! -d ${KODI_ADD} ]] && mkdir -p ${KODI_ADD}
ln -sf ${KODI_OPT}/script.kodi.launches.firefox ${KODI_ADD}/script.kodi.launches.firefox
### Third: Create default addon data:
KODI_DATA=$(dirname ${KODI_ADD})
7z x ${MUK_DIR}/files/kodi_userdata.7z addon_data/script.kodi.launches.firefox -O${KODI_DATA}/

# Third: Copy launcher to the desktop:
#==============================================================================
[[ ! -d ~/Desktop ]] && mkdir -p ~/Desktop
cp /usr/share/applications/firefox.desktop ~/Desktop/
