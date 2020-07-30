#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Home Assistant Supervisor."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installs Home Assistant Supervisor..."
#==============================================================================
# First: Install the prerequisites:
#==============================================================================
apt install -y bash jq curl avahi-daemon dbus software-properties-common apparmor-utils
apt purge -y modemmanager

# Second: Install the supervisor:
#==============================================================================
wget https://raw.githubusercontent.com/home-assistant/supervised-installer/master/installer.sh -O /tmp/installer.sh
chmod +x /tmp/installer.sh
sed -i "s|^set -e|set -e\n. ${MUK_DIR}/files/includes.sh|g" /tmp/installer.sh
sed -i -n "/^docker/{s| > /dev/null||};p" /tmp/installer.sh
sed -i -n "/^docker/{s|\"||g};p" /tmp/installer.sh
sed -i -n "/^docker/{s|^docker |add_outside ${MUK_DIR}/files/docker_cmd.sh |};p" /tmp/installer.sh
/tmp/installer.sh -d /home/docker/hass
rm /tmp/installer.sh

# Third: Disable the supervisor for LiveCD:
#==============================================================================
if ischroot; then
	systemctl disable hassio-supervisor
	systemctl disable hassio-apparmor
fi
