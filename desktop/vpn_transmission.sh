#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Transmission and TransGUI on your computer."
	echo ""
	exit 0
fi

# Seventh: Make sure "nginx" is installed on the system:
#==============================================================================
[[ ! -e /etc/openvpn/freevpn ]] && ${MUK_DIR}/programs/vpn_establish.sh

#==============================================================================
_title "Install Transmission (port 9090)..."
#==============================================================================
# First: Install the software:
#==============================================================================
add-apt-repository -y ppa:transmissionbt/ppa
apt remove -y transmission*
apt install -y transmission-daemon transmission-cli transgui

# Second: Configure the daemon:
#==============================================================================
[[ ! -z "${CHROOT}" ]] && systemctl disable transmission-daemon
[[ -z "${CHROOT}" ]] && systemctl stop transmission-daemon
sed -i "s|User=.*|User=htpc|g" /lib/systemd/system/transmission-daemon.service
sed -i "s|Group=.*|Group=htpc|g" /lib/systemd/system/transmission-daemon.service
sed -i "s|ExecStart|Restart=on-failure\nRestartSec=10\nExecStart|g" /lib/systemd/system/transmission-daemon.service

# Third: Configure the settings for Transmission and TransGUI:
#==============================================================================
# Transmission settings:
[[ ! -d ~/.config/transmission-daemon ]] && mkdir -p ~/.config/transmission-daemon
cp ${MUK_DIR}/files/transmission_settings.json /etc/skel/.config/transmission-daemon/settings.json
change_username /etc/skel/.config/transmission-daemon/settings.json
change_password /etc/skel/.config/transmission-daemon/settings.json
# TransGUI settings:
unzip -o ${MUK_DIR}/files/transgui.zip -d ~/.config/

# Fourth: Reenable the service if NOT running in CHROOT environment:
#==============================================================================
[[ -z "${CHROOT}" ]] && systemctl start transmission-daemon

# Fifth: Create the autoremove.sh script:
#==============================================================================
ln -sf ${MUK_DIR}/files/transmission_autoremove.sh /etc/transmission-daemon/autoremove.sh
change_username /etc/transmission-daemon/autoremove.sh
change_password /etc/transmission-daemon/autoremove.sh

# Sixth: Create the finisher task to create the user "htpc": 
#==============================================================================
[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
ln -sf ${MUK_DIR}/files/tasks.d/40_transmission.sh /usr/local/finisher/tasks.d/40_transmission.sh

# Seventh: Creating our Transmission site reverse proxy:
#==============================================================================
PROG=$(whereis nginx | cut -d" " -f 2)
[[ -z "${PROG}" ]] && ${MUK_DIR}/programs/nginx.sh

cat << EOF > /etc/nginx/sites-available/transmission
server {
    listen 9090;
    server_name example.com;

    location /transmission {
        proxy_pass http://127.0.0.1:19090;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
ln -sf /etc/nginx/sites-available/transmission /etc/nginx/sites-enabled/transmission
