#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Customizing plymouth background with Red Dragon background."
	echo ""
	exit 0
fi

#==============================================================================
_title "Customizing plymouth background..."
#==============================================================================
apt install -y plymouth-theme-xubuntu-logo imagemagick
ROOT=/usr/share/plymouth
DIR=$ROOT/themes/xubuntu-logo/
[[ ! -f ${DIR}/original-wallpaper.png ]] && mv ${DIR}/wallpaper.png ${DIR}/original-wallpaper.png
cp ${MUK_DIR}/files/red_dragon.png ${DIR}/wallpaper.png
FILE=${DIR}/logo.png
test -f ${ROOT}/ubuntu-logo.png && cp ${ROOT}/ubuntu-logo.png ${FILE} && convert -depth 16 ${FILE} ${DIR}/logo_16bit.png 
update-initramfs -u -k $(ls -l /boot/initrd.img | awk '{print $NF}' | sed "s|initrd.img-||")
