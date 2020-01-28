#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Customizes your XFCE appearance."
	echo ""
	exit 0
fi

#==============================================================================
_title "Replacing wallpaper and plymouth background..."
#==============================================================================
DIR=/usr/share/plymouth/themes/xubuntu-logo/
[[ ! -f ${DIR}/wallpaper.png.original ]] && mv ${DIR}/wallpaper.png ${DIR}/wallpaper.png.original
cp /opt/modify_ubuntu_kit/files/red_dragon.png ${DIR}/wallpaper.png
update-initramfs -u

#==============================================================================
_title "Unpacking the new default user UI settings..."
#==============================================================================
# First: Unpack the new XFCE settings:
unzip -o /opt/modify_ubuntu_kit/files/red_dragon.zip -d /etc/skel/.config/

# Second: Create link to new plymouth background:
pushd /usr/share/xfce4/backdrops
[[ -e red-dragon.png ]] && rm red-dragon.png
ln -sf ${DIR}/wallpaper.png red-dragon.png
[[ -e xubuntu-wallpaper.png ]] && rm red-dragon.png
ln -sf red-dragon.png xubuntu-wallpaper.png
popd

# Third: Configuring the LightDM greeter:
#==============================================================================
cat << EOF > /etc/lightdm/lightdm-gtk-greeter.conf
[greeter]
background = /usr/share/xfce4/backdrops/xubuntu-wallpaper.png
theme-name = Adwaita
icon-theme-name = Adwaita
font-name = Noto Sans 12
user-background = false
EOF
