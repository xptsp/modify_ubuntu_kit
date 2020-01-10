#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs some PulseAudio utilities and a PulseAudio systemd service."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install ZeroConf, Avahi, and PulseAudio preference software"
#==============================================================================
# First: Install the software:
#==============================================================================
apt install -y pulseaudio-module-zeroconf avahi-daemon paprefs

# Second: Configure some settings:
#==============================================================================
cat << EOF >> /etc/pulse/system.pa
load-module module-native-protocol-tcp auth-anonymous=1
load-module module-zeroconf-publish
EOF
systemctl enable avahi-daemon

# Third: Prevent PulseAudio from being spawned by user process:
#==============================================================================
sed -i "s|; autospawn = yes|autospawn = no|g" /etc/pulse/client.conf

# Fourth: Add PulseAudio system service:
#==============================================================================
cat << EOF > /etc/systemd/system/pulseaudio.service
[Unit]
Description=PulseAudio Daemon
 
[Service]
Type=simple
PrivateTmp=true
ExecStart=/usr/bin/pulseaudio --system --realtime --disallow-exit --no-cpu-limit 
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable pulseaudio

# Fifth: Add finisher task:
#==============================================================================
if [[ ! -z "${CHROOT}" ]]; then
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/60_pulseaudio.sh /usr/local/finisher/tasks.d/60_pulseaudio.sh
else
	${MUK_DIR}/files/tasks.d/60_pulseaudio.sh
fi
