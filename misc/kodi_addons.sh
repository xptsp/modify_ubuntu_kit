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
_title "Installing a few Kodi addons and activating them..."
#==============================================================================
KODI_ADD=/usr/share/kodi/addons
KODI_OPT=/opt/kodi
KODI_BASE=https://mirrors.kodi.tv/addons/leia/

### First: Install URLresolver from tvaddonsco:
#==============================================================================
#git clone --depth=1 https://github.com/tvaddonsco/script.module.urlresolver ${KODI_OPT}/script.module.urlresolver
#[[ ! -d ~/.kodi/addons ]] && mkdir -p ~/.kodi/addons
#ln -sf ${KODI_OPT}/script.module.urlresolver ~/.kodi/addons/script.module.urlresolver
#kodi_enable script.module.urlresolver

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

### Sixteenth: Pull the "service.system.update" addon:
#==============================================================================
git clone --depth=1 https://github.com/ossman/service.system.update ${KODI_OPT}/service.system.update
ln -sf ${KODI_OPT}/service.system.update ${KODI_ADD}/service.system.update
kodi_enable service.system.update

### Seventeenth: Pull the "repository.primaeval" addon:
#==============================================================================
wget https://github.com/primaeval/repository.primaeval/raw/master/zips/repository.primaeval/repository.primaeval-0.0.2.zip -O /tmp/repository.primaeval-0.0.2.zip
unzip -o /tmp/repository.primaeval-0.0.2.zip -d ${KODI_ADD}/
rm /tmp/repository.primaeval-0.0.2.zip

### Eighteenth: Pull the "plugin.video.iptvsimple.addons"
#==============================================================================
wget https://github.com/primaeval/repository.primaeval/raw/master/krypton/plugin.video.iptvsimple.addons/plugin.video.iptvsimple.addons-0.0.7.zip -O /tmp/plugin.video.iptvsimple.addons-0.0.7.zip
unzip -o /tmp/plugin.video.iptvsimple.addons-0.0.7.zip -d ${KODI_ADD}/
rm /tmp/plugin.video.iptvsimple.addons-0.0.7.zip

### Ninteenth: Pull the "script.module.xbmcswift2" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.xbmcswift2 ${KODI_ADD}/
kodi_enable script.module.xbmcswift2

### Twentieth: Pull the "script.module.beautifulsoup4" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.beautifulsoup4 ${KODI_ADD}/
kodi_enable script.module.beautifulsoup4
