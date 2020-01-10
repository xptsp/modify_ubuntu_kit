#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Unified Remote on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install Unified Remote..."
#==============================================================================
# First: Download and install the software:
#==============================================================================
wget https://www.unifiedremote.com/download/linux-x64-deb -O /tmp/urserver.deb
apt install -y /tmp/urserver.deb
rm /tmp/urserver.deb

# Second: We need to try and fix bluetooth issue (?):
#==============================================================================
sed -i "s|/bluetoothd|/bluetoothd --compat|g" /etc/systemd/system/dbus-org.bluez.service

# Third: Adding Unified Remote systemd service:
#==============================================================================
cat << EOF > /etc/systemd/system/urserver.service
[Unit]
Description=Unified Remote Server
After=syslog.target network.target

[Service]
Environment="HOME=/opt/urserver"
Type=forking
PIDFile=/opt/urserver/.urserver/urserver.pid
ExecStartPre=-/bin/chmod 777 /var/run/sdp
ExecStart=/opt/urserver/urserver-start --no-manager --no-notify
ExecStop=/opt/urserver/urserver-stop

RemainAfterExit=no
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
EOF
chown root:root /etc/systemd/system/urserver.service
systemctl enable urserver
[[ -z "${CHROOT}" ]] && systemctl start urserver