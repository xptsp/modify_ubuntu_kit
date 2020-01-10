#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Builds MyCroft for your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install MyCroft AI..."
# Src: https://www.j1nx.nl/project-1/diy-home-personal-ai-assistant-installing-configuration-part-4/
# Src: https://possiblelossofprecision.net/?p=1956
#==============================================================================
# First: Install/compile the software:
#==============================================================================
apt install -y giblib1 libfm-extra4 libmenu-cache-bin libmenu-cache3 libobrender32v5 libobt2v5 obconf obsession openbox openbox-menu scrot
git clone https://github.com/MycroftAI/mycroft-core.git /opt/mycroft-core
cd /opt/mycroft-core
(echo y; echo y; echo y; echo y; echo y; echo y) | ./dev_setup.sh --allow-root
cd /
change_ownership /opt/mycroft
change_ownership /opt/mycroft-core

# Second: Create a service file:
#==============================================================================
cat << EOF > /etc/systemd/system/mycroft.service
[Unit]
Description=Mycroft personal AI
After=pulseaudio.service
Requires=pulseaudio.service

[Service]
User=kodi
Group=kodi
WorkingDirectory=/opt/mycroft-core
ExecStart=/opt/mycroft-core/start-mycroft.sh all
ExecStop=/opt/mycroft-core/stop-mycroft.sh all
Type=forking
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
if [[ ! -z "${CHROOT}" ]]; then
	systemctl disable mycroft
else
	systemctl enable mycroft
	systemctl start mycroft
fi
chown root:root /etc/systemd/system/mycroft.service
change_username /etc/systemd/system/mycroft.service
