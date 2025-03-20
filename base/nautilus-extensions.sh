#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Nautilus extensions and tweaks."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installs Nautilus options..."
#==============================================================================
mkdir -p  /etc/dconf/{profile,db/local.d}
[[ -f /etc/dconf/profile/user ]] || cat << EOF >  /etc/dconf/profile/user
user-db:user
system-db:local
EOF
STR="${EXTS[@]}"
cat << EOF >  /etc/dconf/db/local.d/00-reddragon-nautilus
# First: Set standard size instead of small icon size  
[org/gnome/nautilus/icon-view]
default-zoom-level='standard'
EOF
dconf update

#==============================================================================
_title "Installs Nautilus extensions available in Ubuntu repo..."
#==============================================================================
test -f /etc/apt/sources.list.d/xptsp_ppa.list || ${MUK_DIR}/base/custom-xptsp.sh
apt install -y nautilus-admin nautilus-extension-brasero nautilus-filename-repairer nautilus-gtkhash \
	nautilus-image-converter nautilus-hide nautilus-wipe folder-color nautilus-gnome-disks  
