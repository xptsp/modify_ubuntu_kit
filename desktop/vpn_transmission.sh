#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Transmission and TransGUI on your computer."
	echo -e "${RED}Dependency:${NC} VPN browser launchers requires FreeVPN to be established."
	echo ""
	exit 0
fi

# Seventh: Make sure our VPN is created on the system:
#==============================================================================
[[ ! -e /etc/openvpn ]] && ${MUK_DIR}/desktop/vpn_establish.sh

#==============================================================================
_title "Install Transmission (port 9090)..."
#==============================================================================
# First: Install the software:
#==============================================================================
add-apt-repository -y ppa:transmissionbt/ppa
apt remove -y transmission*
apt install -y transmission-daemon transmission-cli transgui

# Second: Configure the daemon:
#==============================================================================
ischroot && systemctl disable transmission-daemon
ischroot || systemctl stop transmission-daemon
[[ ! -d /lib/systemd/system/transmission-daemon.service.d ]] && mkdir /lib/systemd/system/transmission-daemon.service.d
cat << EOF > /lib/systemd/system/transmission-daemon.service.d/htpc.conf
[Service]
User=
User=htpc
Group=
Group=htpc
EOF

# Third: Create the "no sleep if transmission-daemon is downloading" service:
#==============================================================================
ln -sf ${MUK_DIR}/files/transmission_nosleep.sh /usr/local/bin/transmission_nosleep.sh
ln -sf ${MUK_DIR}/files/transmission_nosleep.service /etc/systemd/system/transmission_nosleep.service
sed -i "s|/opt/modify_ubuntu_kit|${MUK_DIR}|g" /etc/systemd/system/transmission_nosleep.service
systemctl enable transmission_nosleep
change_username ${MUK_DIR}/files/transmission_nosleep.sh
change_password ${MUK_DIR}/files/transmission_nosleep.sh

# Fourth: Configure the settings for Transmission and TransGUI:
#==============================================================================
# Transmission settings:
[[ ! -d ~/.config/transmission-daemon ]] && mkdir -p ~/.config/transmission-daemon
cp ${MUK_DIR}/files/transmission_settings.json ~/.config/transmission-daemon/settings.json
change_username ~/.config/transmission-daemon/settings.json
change_password ~/.config/transmission-daemon/settings.json
# TransGUI settings:
unzip -o ${MUK_DIR}/files/transgui.zip -d ~/.config/

# Fifth: Reenable the service if NOT running in CHROOT environment:
#==============================================================================
ischroot && systemctl start transmission-daemon

# Sixth: Create the autoremove.sh script:
#==============================================================================
ln -sf ${MUK_DIR}/files/transmission_autoremove.sh /etc/transmission-daemon/autoremove.sh
change_username /etc/transmission-daemon/autoremove.sh
change_password /etc/transmission-daemon/autoremove.sh

# Seventh: Create the finisher task to create the user "htpc": 
#==============================================================================
add_taskd 40_transmission.sh

# Eighth: Create the "transmission_nosleep" service:
#==============================================================================
cp ${MUK_DIR}/files/transmission_nosleep.service /etc/systemd/system/transmission_nosleep.service
systemctl enable transmission_nosleep

#==============================================================================
_title "Install Transmission addon for Kodi..."
#==============================================================================
### First: Get the "script.module.beautifulsoup" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.beautifulsoup ${KODI_ADD}/
kodi_enable script.module.beautifulsoup

### Second: Pull the "script.module.simplejson" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.simplejson ${KODI_ADD}/
kodi_enable script.module.simplejson

### Third: Pull the "script.module.six" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.six ${KODI_ADD}/
kodi_enable script.module.six

### Fourth: Pull the "script.transmission" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.transmission ${KODI_ADD}/
kodi_enable script.transmission
