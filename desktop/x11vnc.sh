#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs X11VNC on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install X11VNC for viewing screen while running..."
#==============================================================================
apt install -y x11vnc
[ -f /etc/x11vnc.pass ] && rm /etc/x11vnc.pass

# Second: Install X11VNC service file to launch automatically:
#==============================================================================
cat << EOF > /etc/systemd/system/x11vnc.service
[Unit]
Description=X11VNC Display Server
Requires=display-manager.service
After=display-manager.service

[Service]
ExecStart=/usr/bin/x11vnc -xkb -noxrecord -noxfixes -noxdamage -display :0 -auth guess -rfbauth /etc/x11vnc.pass -speeds modem
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure
Restart-sec=2

[Install]
WantedBy=multi-user.target
EOF
chown root:root /etc/systemd/system/x11vnc.service

# Third: Adding X11VNC finisher task:
#==============================================================================
AO=$(ischroot && echo "disable" || echo "enable")
systemctl ${AO} x11vnc
add_taskd 20_x11vnc.sh
! ischroot && systemctl start x11vnc
