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
test -f /etc/apt/sources.list.d/xptsp_ppa.list || ${MUK_DIR}/base/custom-xptsp.sh
apt install -y kodi-openbox

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
echo ${THIS_RUN} > /tmp/last_run

# If Kodi ran for more than 10 seconds, then do these lines:
[[ \$((\${THIS_RUN} - \${LAST_RUN})) -lt 10 ]] && exit

# Run the "b4_restart" script before a restart of Kodi if it exists:
[[ -x \${HOME}/.kodi-openbox/b4_restart ]] && (\${HOME}/.kodi-openbox/b4_restart; rm \${HOME}/.kodi-openbox/b4_restart)

# Exit this script if the "no_restart" file exists:
[[ -f \${HOME}/.kodi-openbox/no_restart ]] && exit

# Otherwise, restart Kodi openbox:
/usr/bin/kodi-openbox-session
EOF
chown root:root ~/.kodi-openbox/onfinish
chmod +x ~/.kodi-openbox/onfinish
cp ~/.kodi-openbox/onfinish ~/.kodi-openbox/onkill

### Fifth: Set up the LAST_RUN variable for "onfinish" script:
#==============================================================================
cat << EOF > ~/.kodi-openbox/onstart
#!/bin/bash
# Put some code here to run when a kodi-openbox session successfully starts

# Record last start of Kodi:
echo \$(date +%s) > /tmp/.kodi_last_run

# Start SoundWire Server if available:
pgrep SoundWireServer || /opt/SoundWireServer/start-soundwire -nogui &

# Execute the kodi binding script:
sudo /usr/local/bin/kodi_bind.sh
EOF
chown root:root ~/.kodi-openbox/onstart
chmod +x ~/.kodi-openbox/onstart

### Sixth: Link the "kodi-bind.sh" script:
#==============================================================================
[[ ! -d /mnt/hdd ]] && mkdir -p /mnt/hdd
ln -sf ${MUK_DIR}/files/kodi-bind.sh /usr/local/bin/kodi-bind.sh

### Seventh: Create sudoers.d rule to run "kodi-bind.sh" as root:
#==============================================================================
echo "ALL ALL=(ALL) NOPASSWD:/usr/local/bin/kodi-bind.sh" >> /etc/sudoers.d/kodi-bind
