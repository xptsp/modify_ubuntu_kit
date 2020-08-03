#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Kodi on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Kodi..."
#==============================================================================
### First: Install the software (duh):
#==============================================================================
apt-add-repository -y ppa:team-xbmc/ppa
apt install -y kodi kodi-pvr-iptvsimple kodi-visualization-[wgs]* kodi-peripheral-* kodi-screensaver-* kodi-eventclients-kodi-send

### Second: Copy the Harmony Remote keymap and adjust the keymap a little:
### Original Source: https://forum.kodi.tv/showthread.php?tid=188542
#==============================================================================
[[ ! -d ${HOME}/.kodi/userdata/keymaps ]] && mkdir -p ${HOME}/.kodi/userdata/keymaps
cp ${MUK_DIR}/files/harmony_remote.xml ${HOME}/.kodi/userdata/keymaps/harmony_remote.xml
sed -i '/FullScreen/d' ${HOME}/.kodi/userdata/keymaps/harmony_remote.xml
sed -i '/XBMC.ShutDown()/d' ${HOME}/.kodi/userdata/keymaps/harmony_remote.xml

### Third: Download the default Kodi settings:
#==============================================================================
7z x ${MUK_DIR}/files/kodi_userdata.7z -aoa -o${HOME}/.kodi/userdata/

### Fourth: Create a post-install task to finish configuring Kodi:
#==============================================================================
add_taskd 50_kodi.sh

#==============================================================================
_title "Installing a few Kodi addons and activating them..."
#==============================================================================
### First: Pull the "script.module.beautifulsoup4" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.beautifulsoup4 ${KODI_ADD}/
kodi_enable script.module.beautifulsoup4

### Second: Pull the "weather.yahoo" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/weather.yahoo ${KODI_ADD}/
kodi_enable weather.yahoo

### Third: Pull the "script.module.certifi" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.certifi ${KODI_ADD}/
kodi_enable script.module.certifi

### Fourth: Pull the "script.module.chardet" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.chardet ${KODI_ADD}/
kodi_enable script.module.chardet

### Fifth: Pull the "script.module.idna" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.idna ${KODI_ADD}/
kodi_enable script.module.idna

### Sixth: Pull the "script.module.requests" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.requests ${KODI_ADD}/
kodi_enable script.module.requests

### Seventh: Pull the "script.module.urllib3" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.urllib3 ${KODI_ADD}/
kodi_enable script.module.urllib3

### Eighth: Pull the "script.module.bottle" addon
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.bottle ${KODI_ADD}/
kodi_enable script.module.bottle

### Ninth: Pull the "script.module.urllib3" addon
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.urllib3 ${KODI_ADD}/
kodi_enable script.module.urllib3

### Tenth: Pull the "script.module.urllib3" addon
#==============================================================================
kodi_repo ${KODI_BASE}/plugin.video.youtube ${KODI_ADD}/
kodi_enable plugin.video.youtube

### Eleventh: Pull the "script.onmute" addon
#==============================================================================
kodi_repo ${KODI_BASE}/service.onmute ${KODI_ADD}/
kodi_enable service.onmute

### Twelveth: Pull the "script.tubecast" addon
#==============================================================================
kodi_repo ${KODI_BASE}/script.tubecast ${KODI_ADD}/
kodi_enable script.tubecast

### Thirteenth: Pull the "script.xbmc.unpausejumpback" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.xbmc.unpausejumpback ${KODI_ADD}/
kodi_enable script.xbmc.unpausejumpback

### Fourteenth: Pull the "service.subtitles.subscene" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/service.subtitles.subscene ${KODI_ADD}/
kodi_enable service.subtitles.subscene

### Fifteenth: Pull the "context.copytostorage" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/context.copytostorage ${KODI_ADD}/
kodi_enable context.copytostorage

### Sixteenth: Pull the "script.module.xbmcswift2" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.xbmcswift2 ${KODI_ADD}/
kodi_enable script.module.xbmcswift2

