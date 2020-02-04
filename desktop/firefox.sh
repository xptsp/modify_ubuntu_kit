#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Mozilla Firefox and Thunderbird on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Mozilla Firefox and Thunderbird..."
#==============================================================================
# First: Install the software:
#==============================================================================
apt install -y firefox thunderbird

# Second: Install the Kodi addon:
#==============================================================================
KODI_OPT=${KODI_OPT:-"/opt/kodi"}
KODI_ADD=/usr/share/kodi/addons

### First: Get the repo:
[[ ! -d ${KODI_OPT} ]] && mkdir -p ${KODI_OPT}
git clone --depth=1 https://github.com/xptsp/script.kodi.launches.firefox ${KODI_OPT}/script.kodi.launches.firefox
### Second: Link the repo:
[[ ! -d ${KODI_ADD} ]] && mkdir -p ${KODI_ADD}
ln -sf ${KODI_OPT}/script.kodi.launches.firefox ${KODI_ADD}/script.kodi.launches.firefox
### Third: Enable addon by default:
kodi_enable script.kodi.launches.firefox

# Third: Copy launcher to the desktop:
#==============================================================================
[[ ! -d ~/Desktop ]] && mkdir -p ~/Desktop
cp /usr/share/applications/firefox.desktop ~/Desktop/
chmod +x ~/Desktop/firefox.desktop
cp /usr/share/applications/thunderbird.desktop ~/Desktop/
chmod +x ~/Desktop/thunderbird.desktop
