#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs CouchPotato on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing CouchPotato (port 5050)..."
#==============================================================================
# First: Install the dependencies:
#==============================================================================
apt install -y python-lxml libxml2-dev libxslt-dev python-openssl python-cryptography git-core libffi-dev libssl-dev zlib1g-dev libxslt1-dev libxml2-dev python python-pip python-dev build-essential -y

# Second: Clone the repository:
#==============================================================================
git clone --depth=1 https://github.com/RuudBurger/CouchPotatoServer /opt/couchpotato
relocate_dir /opt/couchpotato
change_ownership /opt/couchpotato

# Third : Customize the service file:
#==============================================================================
cp /opt/couchpotato/init/couchpotato.service /etc/systemd/system/couchpotato.service
[[ ! -d /etc/systemd/system/couchpotato.service.d ]] && mkdir -p /etc/systemd/system/couchpotato.service.d
cat << EOF > /etc/systemd/system/couchpotato.service.d/htpc.conf
[Service]
User=
User=htpc
Group=
Group=users
ExecStart=
ExecStart=/opt/couchpotato/CouchPotato.py
EOF

# Fourth: Create finisher task
#==============================================================================
if ischroot; then
	systemctl disable couchpotato
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/40_couchpotato.sh /usr/local/finisher/tasks.d/40_couchpotato.sh
else
	${MUK_DIR}/files/tasks.d/40_couchpotato.sh
	systemctl enable couchpotato
	systemctl start couchpotato
fi

#==============================================================================
_title "Installing CouchPotato addons for Kodi..."
#==============================================================================
### First: Install the couchpotato manager addon:
#==============================================================================
kodi_repo plugin.video.couchpotato_manager
kodi_enable plugin.video.couchpotato_manager

### Second: Install the dependency:
#==============================================================================
kodi_repo script.module.xbmcswift2
kodi_enable script.module.xbmcswift2
