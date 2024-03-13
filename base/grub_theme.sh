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
# Extract archived copy of theme:
cd /boot/grub
mkdir -p themes/red_dragon
cd themes/red_dragon
tar xf ${MUK_DIR}/files/grub_theme.tar.xz
# Copy E2B background to new theme:
cp ${MUK_DIR}/files/e2b_red_dragon.png background.png
# Add necessary stuff to default grub settings:
cat << EOF >> /etc/default/grub
GRUB_GFXMODE=1920x1080
GRUB_THEME="/boot/grub/themes/red_dragon/theme.txt"
EOF
# Update grub configuration file:
update-grub
