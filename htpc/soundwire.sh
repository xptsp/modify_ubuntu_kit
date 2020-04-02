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
apt install -y libcurl3 libqt5widgets5 libportaudio2 pavucontrol
wget http://georgielabs.altervista.org/SoundWire_Server_linux64.tar.gz -O /tmp/SoundWire_Server_linux64.tar.gz
tar -xzf /tmp/SoundWire_Server_linux64.tar.gz -C /opt/
rm /tmp/SoundWire_Server_linux64.tar.gz
chown root:root -R /opt/SoundWireServer
change_ownership /opt/SoundWireServer

# Second: Create a script to launch the program using right PulseAudio settings:
#==============================================================================
cat << EOF > /opt/SoundWireServer/start-soundwire
#!/bin/bash
export PULSE_SOURCE=
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:\${LD_LIBRARY_PATH}
cd /opt/SoundWireServer
./SoundWireServer \$@
EOF
chown root:root /opt/SoundWireServer/start-soundwire
chmod +x /opt/SoundWireServer/start-soundwire

# Third: Create a menu launcher for SoundWire Server
#==============================================================================
cat << EOF > /usr/share/applications/soundwire.desktop
[Desktop Entry]
Name=SoundWire Server
Comment=SoundWire Android server
Exec=/opt/SoundWireServer/start-soundwire
Icon=/opt/SoundWireServer/sw-icon.xpm
Terminal=false
Type=Application
Categories=AudioVideo;Audio
EOF
chown root:root /usr/share/applications/soundwire.desktop

# Fourth: Add 