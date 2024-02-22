#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Transmission and Transmission Remote GTK on your computer."
	echo ""
	exit 0
fi

# Seventh: Make sure our VPN is created on the system:
#==============================================================================
[[ ! -e /etc/openvpn ]] && ${MUK_DIR}/desktop/vpn_establish.sh

#==============================================================================
_title "Installing Transmission (port 9090)..."
#==============================================================================
# First: Install the software:
#==============================================================================
add-apt-repository -y ppa:transmissionbt/ppa
FILE=/etc/apt/sources.list.d/transmissionbt-ubuntu-ppa-*.list
sed -i "s| impish | focal |g" ${FILE}
sed -i "s| jammy | focal |g" ${FILE}
apt update
apt remove -y transmission*
apt install -y transmission-daemon transmission-cli

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

# Fourth: Configure the settings for Transmission:
#==============================================================================
# Transmission settings:
[[ ! -d ~/.config/transmission-daemon ]] && mkdir -p ~/.config/transmission-daemon
cp ${MUK_DIR}/files/transmission_settings.json ~/.config/transmission-daemon/settings.json
change_username ~/.config/transmission-daemon/settings.json
change_password ~/.config/transmission-daemon/settings.json

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
