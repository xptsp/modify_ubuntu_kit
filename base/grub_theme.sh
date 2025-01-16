#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Red Dragon grub theme..."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Red Dragon Grub2 theme..."
#==============================================================================
test -f /etc/apt/sources.list.d/xptsp_ppa.list || ${MUK_DIR}/base/custom-xptsp.sh
apt install -y grub-theme-reddragon

# Add necessary stuff to default grub settings:
_title "Updating grub configuration file..."
cat << EOF >> /etc/default/grub
GRUB_GFXMODE=1920x1080
GRUB_THEME="/usr/share/grub/themes/reddragon/theme.txt"
GRUB_DISABLE_OS_PROBER=false
EOF
update-grub
