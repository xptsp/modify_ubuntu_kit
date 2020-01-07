#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs SoundWire on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing SoundWire Server"
#==============================================================================
# First: Download the software (duh! :p)
#==============================================================================
wget http://georgielabs.altervista.org/SoundWire_Server_linux64.tar.gz -O /tmp/SoundWire_Server_linux64.tar.gz
tar -xzf /tmp/SoundWire_Server_linux64.tar.gz -C /opt/
rm /tmp/SoundWire_Server_linux64.tar.gz
chown root:root -R /opt/SoundWireServer
change_ownership /opt/SoundWireServer

# Second: Create a script to launch the program using right PulseAudio settings:
#==============================================================================
cat << EOF > /opt/SoundWireServer/start-soundwire
#!/bin/sh
export PULSE_SOURCE=
/opt/SoundWireServer/SoundWireServer \$@
EOF
chown root:root /opt/SoundWireServer/start-soundwire
chmod +x /opt/SoundWireServer/start-soundwire

# Third: Create a menu launcher for SoundWire Server
#==============================================================================
cat << EOF > /usr/share/applications/soundwire.desktop
[Desktop Entry]
Name=SoundWire Server
Comment=Server program for SoundWire Android app
Exec=/opt/SoundWireServer/start-soundwire
Icon=/opt/SoundWireServer/sw-icon.xpm
Terminal=false
Type=Application
Categories=AudioVideo;Audio
EOF
chown root:root /usr/share/applications/soundwire.desktop

# Fourth: Create a service to launch it
#==============================================================================
cat << EOF > /etc/systemd/system/soundwire.service
[Unit]
Description=SoundWire Server

[Service]
Type=simple
User=kodi
Group=kodi
ExecStart=/opt/SoundWireServer/start-soundwire -nogui
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
systemctl disable soundwire
chown root:root /etc/systemd/system/soundwire.service
change_username /etc/systemd/system/soundwire.service
