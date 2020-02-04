#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs the latest version of Emby Server on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Emby Server (port 8096)..."
# NOTE: Port 8096, Default user: "kodi", password: "xubuntu"
#==============================================================================
# First: Link to the "upgrade_emby.sh" script:
#==============================================================================
ln -sf ${MUK_DIR}/files/emby_upgrade.sh /usr/local/bin/emby_upgrade

# Second: Install the software (duh :p)
#==============================================================================
/usr/local/bin/emby_upgrade
ischroot && systemctl disable emby-server
relocate_dir /var/lib/emby

# Third: Pull the default settings for Emby:
#==============================================================================
ischroot || systemctl stop emby-server
7z x ${MUK_DIR}/files/emby_settings.7z -aoa -o/var/lib/emby/
chown emby:emby -R /var/lib/emby
ischroot || systemctl start emby-server

#==============================================================================
_title "Installing Emby for Kodi addons..."
#==============================================================================
### First: Set "KODI_ADD" variable if not set:
KODI_OPT=${KODI_OPT:-"/opt/kodi"}
KODI_ADD=/usr/share/kodi/addons

### Second: Get "Emby-Kodi" repository:
wget http://kodi.emby.media/repository.emby.kodi-1.0.6.zip -O /tmp/repository.emby.kodi-1.0.6.zip
7z x /tmp/repository.emby.kodi-1.0.6.zip -aoa -o${KODI_ADD}/
rm /tmp/repository.emby.kodi-1.0.6.zip
### Third: Get the "plugin.video.emby.movies" addon:
wget https://embydata.com/downloads/addons/xbmb3c/multi-repo/krypton/plugin.video.emby.movies/plugin.video.emby.movies-0.14.zip -O /tmp/plugin.video.emby.movies-0.14.zip
7z x /tmp/plugin.video.emby.movies-0.14.zip -aoa -o${KODI_ADD}/
rm /tmp/plugin.video.emby.movies-0.14.zip
### Fourth: Get the "plugin.video.emby.musicvideos" addon:
wget https://embydata.com/downloads/addons/xbmb3c/multi-repo/krypton/plugin.video.emby.musicvideos/plugin.video.emby.musicvideos-0.14.zip -O /tmp/plugin.video.emby.musicvideos-0.14.zip
7z x /tmp/plugin.video.emby.musicvideos-0.14.zip -aoa -o${KODI_ADD}/
rm /tmp/plugin.video.emby.musicvideos-0.14.zip
### Fifth: Get the "plugin.video.empty.tvshows" addon:
wget https://embydata.com/downloads/addons/xbmb3c/multi-repo/krypton/plugin.video.emby.tvshows/plugin.video.emby.tvshows-0.14.zip -O /tmp/plugin.video.emby.tvshows-0.14.zip
7z x /tmp/plugin.video.emby.tvshows-0.14.zip -aoa -o${KODI_ADD}/
rm /tmp/plugin.video.emby.tvshows-0.14.zip
### Sixth: Get the "plugin.video.emby" addon:
wget https://embydata.com/downloads/addons/xbmb3c/multi-repo/krypton/plugin.video.emby/plugin.video.emby-4.1.10.zip -O /tmp/plugin.video.emby-4.1.10.zip
7z x /tmp/plugin.video.emby-4.1.10.zip -aoa -o${KODI_ADD}/
rm /tmp/plugin.video.emby-4.1.10.zip
### Seventh: Get the "service.upnext" addon:
wget https://embydata.com/downloads/addons/xbmb3c/multi-repo/krypton/service.upnext/service.upnext-1.0.3.zip -O /tmp/service.upnext-1.0.3.zip
7z x /tmp/service.upnext-1.0.3.zip -aoa -o${KODI_ADD}/
rm /tmp/service.upnext-1.0.3.zip

### Eighth: Enable all these addons:
kodi_enable repository.emby.kodi
kodi_enable plugin.video.emby.movies
kodi_enable plugin.video.emby.musicvideos
kodi_enable plugin.video.emby.tvshows
kodi_enable plugin.video.emby
kodi_enable service.upnext
