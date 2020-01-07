#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Kodi OpenBox on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing OpenBox for Kodi..."
#==============================================================================
### First: Set up Openbox for running Kodi:
#==============================================================================
apt -y install openbox unzip hsetroot gifsicle httping expect

### Second: Compile the "kodi-openbox" package:
#==============================================================================
git clone --depth=1 https://github.com/lufinkey/kodi-openbox /tmp/kodi-openbox
pushd /tmp/kodi-openbox
./build.sh
apt install -y /tmp/kodi-openbox.deb
popd
rm -rf /tmp/kodi-openbox

### Third: Set up a few elements of Openbox:
#==============================================================================
cp -R /etc/xdg/openbox ~/.config/openbox/
cat << EOF >> ~/.config/openbox/autostart

# Set a background color
hsetroot -solid black
# Disable screen saver
xset s off
# Disable screen blanking
xset s noblank
# Disable "Display Power Management Signaling"
xset -dpms
EOF
chown root:root ~/.config/openbox/autostart
chmod +x ~/.config/openbox/autostart

### Fourth: Set up automatic restart for Kodi
#==============================================================================
mkdir ~/.kodi-openbox
cat << EOF > ~/.kodi-openbox/onfinish
#!/bin/bash
if [[ -f \${HOME}/.kodi-openbox/norestart ]]; then
    rm \${HOME}/.kodi-openbox/norestart
else
    /usr/bin/kodi-openbox-session
fi
EOF
chown root:root ~/.kodi-openbox/onfinish
chmod +x ~/.kodi-openbox/onfinish
cp ~/.kodi-openbox/onfinish ~/.kodi-openbox/onkill
