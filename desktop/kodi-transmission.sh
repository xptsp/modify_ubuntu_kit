#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Transmission addon for Kodi on your computer."
	echo ""
	exit 0
fi

# Seventh: Make sure our VPN is created on the system:
#==============================================================================
[[ ! -e /etc/openvpn ]] && ${MUK_DIR}/desktop/vpn_establish.sh

#==============================================================================
_title "Install Transmission addon for Kodi..."
#==============================================================================
# First: Create the "transmission_nosleep" service:
#==============================================================================
cp ${MUK_DIR}/files/transmission_nosleep.service /etc/systemd/system/transmission_nosleep.service
systemctl enable transmission_nosleep

#==============================================================================
_title "Install Transmission addon for Kodi..."
#==============================================================================
### First: Get the "script.module.beautifulsoup" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.beautifulsoup ${KODI_ADD}/
kodi_enable script.module.beautifulsoup

### Second: Pull the "script.module.simplejson" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.simplejson ${KODI_ADD}/
kodi_enable script.module.simplejson

### Third: Pull the "script.module.six" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.module.six ${KODI_ADD}/
kodi_enable script.module.six

### Fourth: Pull the "script.transmission" addon:
#==============================================================================
kodi_repo ${KODI_BASE}/script.transmission ${KODI_ADD}/
kodi_enable script.transmission
