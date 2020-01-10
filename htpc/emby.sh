#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs the latest version of Emby Server on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Emby Server (port 8096)..."
# NOTE: Port 8096, Default user: "kodi", password: "xubuntu"
#==============================================================================
# First: Link to the "upgrade_emby.sh" script:
#==============================================================================
ln -sf ${MUK_DIR}/files/emby_upgrade.sh /usr/local/bin/emby_upgrade

# Second: Install the software (duh :p)
#==============================================================================
/usr/local/bin/emby_upgrade
[[ ! -z "${CHROOT}" ]] && systemctl disable emby-server
relocate_dir /var/lib/emby

# Third: Pull the default settings for Emby:
#==============================================================================
7z x ${MUK_DIR}/files/emby_settings.7z -aoa -o/var/lib/emby/
chown emby:emby -R /var/lib/emby/*
