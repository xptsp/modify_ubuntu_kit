#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Upgrades and configures Bluetooth software"
	echo ""
	exit 0
fi

#==============================================================================
_title "Upgrade and configure the Bluetooth software"
#==============================================================================
### Src: https://bbs.archlinux.org/viewtopic.php?id=204079

# First: Install the software:
#==============================================================================
[[ "$OS_VER" -eq 1804 ]] && add-apt-repository -y ppa:bluetooth/bluez
apt install -y pulseaudio pulseaudio-utils pavucontrol pulseaudio-module-bluetooth

# Second: Alter the bluetooth service file:
#==============================================================================
[[ ! -d /etc/systemd/system/dbus-org.bluez.service.d ]] && mkdir -p /etc/systemd/system/dbus-org.bluez.service.d
cat << EOF > /etc/systemd/system/dbus-org.bluez.service.d/compat.conf
[Service]
ExecStart=
ExecStart=/usr/lib/bluetooth/bluetoothd --compat
EOF

# Third: Create the missing audio.conf file:
#==============================================================================
cat << EOF > /etc/bluetooth/audio.conf
# This section contains general options
[General]
Enable=Source,Sink,Media,Socket
EOF
