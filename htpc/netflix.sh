#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Netflix for Kodi on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Netflix for Kodi..."
#==============================================================================
KODI_OPT=${KODI_OPT:-"/opt/kodi"}
KODI_ADD=/usr/share/kodi/addons

### First: Pull the "script.module.addon.signals" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.addon.signals ${KODI_ADD}/
kodi_enable script.module.addon.signals

### Second: Pull the "script.module.certifi" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.certifi ${KODI_ADD}/
kodi_enable script.module.certifi

### Third: Pull the "script.module.chardet" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.chardet ${KODI_ADD}/
kodi_enable script.module.chardet

### Fourth: Pull the "script.module.future" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.future ${KODI_ADD}/
kodi_enable script.module.future

### Fifth: Pull the "script.module.idna" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.idna ${KODI_ADD}/
kodi_enable script.module.idna

### Sixth: Pull the "script.module.inputstreamhelper" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.inputstreamhelper ${KODI_ADD}/
kodi_enable script.module.inputstreamhelper

### Seventh: Pull the "script.module.requests" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.requests ${KODI_ADD}/
kodi_enable script.module.requests

### Eighth: Pull the "script.module.urllib3" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.urllib3 ${KODI_ADD}/
kodi_enable script.module.urllib3

### Ninth: Pull the "plugin.video.netflix" addon:
#==============================================================================
wget https://github.com/CastagnaIT/repository.castagnait/blob/master/zip/plugin.video.netflix/plugin.video.netflix-0.16.4.zip -O /tmp/plugin.video.netflix-0.16.4.zip
unzip /tmp/plugin.video.netflix-0.16.4.zip -O ${KODI_ADD}/
kodi_enable plugin.video.netflix

### Tenth: Pull the "repository.castagnait" addon:
#==============================================================================
wget https://github.com/castagnait/repository.castagnait/raw/master/repository.castagnait-1.0.0.zip -O /tmp/repository.castagnait-1.0.0.zip
unzip /tmp/repository.castagnait-1.0.0.zip -O ${KODI_ADD}/
kodi_enable repository.castagnait

### Eleventh: Get Widevine Library:
#==============================================================================
wget https://redirector.gvt1.com/edgedl/widevine-cdm/970-linux-x64.zip -O /tmp/970-linux-x64.zip
unzip -o /tmp/970-linux-x64.zip -d $(dirname ${KODI_ADD})/cdm
rm /tmp/970-linux-x64.zip
