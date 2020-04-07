#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs the most current version of RetroPie on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing the RetroPie software..."
#==============================================================================
### First: Install the software:
#==============================================================================
apt install -y git dialog unzip xmlstarlet
git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git /opt/RetroPie-Setup

### Second: Move stuff around so that the folders are created for each user:
#==============================================================================
cd /opt/RetroPie-Setup && __nodialog=1 ./retropie_packages.sh setup basic_install && cd /
mv /root/RetroPie ~/
mv /root/.atari800.cfg ~/
mv /root/.emulationstation ~/
mv /root/.config/retroarch ~/.config/
change_ownership /opt/RetroPie-Setup
change_ownership /opt/retropie

### Third: Pull the "script.kodi.launches.emulationstation" addon:
#==============================================================================
### First: Get the repo:
[[ ! -d ${KODI_OPT} ]] && mkdir -p ${KODI_OPT}
git clone --depth=1 https://github.com/BrosMakingSoftware/Kodi-Launches-EmulationStation-Addon ${KODI_OPT}/Kodi-Launches-EmulationStation-Addon
### Second: Link the repo:
[[ ! -d ${KODI_ADD} ]] && mkdir -p ${KODI_ADD}
ln -sf ${KODI_OPT}/Kodi-Launches-EmulationStation-Addon/script.kodi.launches.emulationstation ${KODI_ADD}/script.kodi.launches.emulationstation
### Third: Enable addon by default:
kodi_enable script.kodi.launches.emulationstation
