#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs the most current version of Network Caller ID (NCID) on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing NCID (Network Caller ID)..."
#==============================================================================
# First: Pull the NCID packages we need:
#==============================================================================
NCID_VER=1.11
wget https://sourceforge.net/projects/ncid/files/ncid/${NCID_VER}/ncid_${NCID_VER}-1_amd64.deb -O /tmp/ncid_${NCID_VER}-1_amd64.deb
wget https://sourceforge.net/projects/ncid/files/ncid/${NCID_VER}/ncid-client_${NCID_VER}-1_all.deb -O /tmp/ncid-client_${NCID_VER}-1_all.deb

# Second: Install the NCID Server and Client packages
#==============================================================================
apt install -y libpcap0.8-dev libpcre3-dev curl /tmp/ncid_${NCID_VER}-1_amd64.deb /tmp/ncid-client_${NCID_VER}-1_all.deb
rm /tmp/ncid_${NCID_VER}-1_amd64.deb
rm /tmp/ncid-client_${NCID_VER}-1_all.deb

# Third: Remove the "mailutils" package:
#==============================================================================
apt remove --purge -y mailutils-common postfix

# Fourth: Reconfigure server so that it doesn't require a modem:
#==============================================================================
sed -i "s|# set cidinput = 3|set cidinput = 3|g" /etc/ncid/ncidd.conf
ischroot || systemctl disable ncidd

# Fidth: Fix a few improperly marked executable service files:
#==============================================================================
chmod -x /usr/lib/systemd/system/ncid*.service

# Sixth: Create the notification service from NCID to Kodi:
#==============================================================================
ln -sf ${MUK_DIR}/files/kodi_ncid.sh /usr/share/ncid/modules/ncid_kodi
ln -sf /usr/lib/systemd/system/ncid-page.service /usr/lib/systemd/system/kodi_ncid.service
[[ ! -d /usr/lib/systemd/system/kodi_ncid.service.d ]] && mkdir -p /usr/lib/systemd/system/kodi_ncid.service.d
cat << EOF > /usr/lib/systemd/system/kodi_ncid.service.d/customize.conf
[Unit]
Description=NCID client using the Kodi Module

[Service]
PIDFile=
PIDFile=/run/kodi_ncid.pid
ExecStart=
ExecStart=/usr/bin/ncid --no-gui --pidfile /run/kodi_ncid.pid -P kodi_ncid
EOF
if ischroot; then
	systemctl disable kodi_ncid
else
	systemctl enable kodi_ncid
	systemctl start kodi_ncid
fi
