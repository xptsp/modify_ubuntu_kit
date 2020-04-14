#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs SickChill on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing SickChill (port 8081)..."
#==============================================================================
# First: Install the dependencies:
#==============================================================================
apt install -y unrar-free git-core openssl libssl-dev python2.7

# Second: Clone the repository:
#==============================================================================
git clone --depth=1 https://github.com/SickChill/SickChill.git /opt/sickchill
relocate_dir /opt/sickchill

# Third: Copy the service file and set defaults:
===============================================================================
cp /opt/sickchill/runscripts/init.systemd /etc/systemd/system/sickchill.service
[[ ! -d /etc/systemd/system/sickchill.service.d ]] && mkdir -p /etc/systemd/system/sickchill.service.d
cat << EOF > /etc/systemd/system/sickchill.service.d/htpc.conf
[Service]
User=
User=htpc
Group=
Group=htpc
ExecStart=
ExecStart=/opt/sickchill/SickBeard.py -q --daemon --nolaunch --datadir=/opt/sickchill
EOF

# Fourth: Get the configuration file:
#==============================================================================
unzip ${MUK_DIR}/files/sickchill_settings.zip -d /opt/sickchill/
change_username /opt/sickchill/config.ini

# Fifth: Create finisher task
#==============================================================================
if ischroot; then
	systemctl disable sickchill
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/40_sickchill.sh /usr/local/finisher/tasks.d/40_sickchill.sh
else
	systemctl enable sickchill
	systemctl start sickchill
	${MUK_DIR}/files/tasks.d/40_sickchill.sh
fi	

#==============================================================================
_title "Installing SickChill addon for Kodi..."
#==============================================================================
### First: We need the repository:
#==============================================================================
wget https://github.com/Hiltronix/repo/raw/master/repository.Hiltronix.zip -O /tmp/repository.Hiltronix.zip
7z x /tmp/repository.Hiltronix.zip -aoa -o${KODI_ADD}/
rm /tmp/repository.Hiltronix.zip
kodi_enable repository.Hiltronix

### Second: We need the addon:
#==============================================================================
git clone --depth=1 https://github.com/Hiltronix/plugin.video.sickrage ${KODI_OPT}/plugin.video.sickrage
ln -sf ${KODI_OPT}/plugin.video.sickrage ${KODI_ADD}/plugin.video.sickrage
kodi_enable plugin.video.sickrage

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
