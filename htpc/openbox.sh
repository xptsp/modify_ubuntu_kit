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
apt install -y /tmp/kodi-openbox/kodi-openbox.deb
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
[[ ! -d ~/.kodi-openbox ]] && mkdir -p ~/.kodi-openbox
cat << EOF > ~/.kodi-openbox/onfinish
#!/bin/bash

# Get last run time, then update to current time:
LAST_RUN=\$(cat /tmp/.kodi_last_run 2> /dev/null || echo "0")
THIS_RUN=\$(date +%s)
echo ${THIS_RUN} > \${HOME}/.kodi-openbox/last_run

# If Kodi ran for more than 10 seconds, then do these lines:
[[ \$((\${THIS_RUN} - \${LAST_RUN})) -lt 10 ]] && exit

# Run the "b4_restart" script before a restart of Kodi if it exists:
[[ -x \${HOME}/.kodi-openbox/b4_restart ]] && (\${HOME}/.kodi-openbox/b4_restart; rm \${HOME}/.kodi-openbox/b4_restart)

# Exit this script if the "no_restart" file exists:
[[ -f \${HOME}/.kodi-openbox/no_restart ]] && exit

# Otherwise, restart Kodi openbox:
/usr/bin/kodi-openbox-session
fi
EOF
chown root:root ~/.kodi-openbox/onfinish
chmod +x ~/.kodi-openbox/onfinish
cp ~/.kodi-openbox/onfinish ~/.kodi-openbox/onkill

### Fifth: Set up the LAST_RUN variable for "onfinish" script:
#==============================================================================
cat << EOF >> ~/.kodi-openbox/onstart

# Record last start of Kodi:
echo \$(date +%s) > /tmp/.kodi_last_run

# Start SoundWire Server if available:
pgrep SoundWireServer || /opt/SoundWireServer/start-soundwire -nogui &
EOF
chown root:root ~/.kodi-openbox/onstart
chmod +x ~/.kodi-openbox/onstart
