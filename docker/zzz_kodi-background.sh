#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Replaces XFCE default background."
	echo ""
	exit 0
fi

#==============================================================================
_title "Replacing XFCE default background...."
#==============================================================================
wget https://wallpapercave.com/wp/wp1809298.png -O /tmp/kodi.jpg
pushd /usr/share/xfce4/backdrops >& /dev/null
convert /tmp/kodi.jpg kodi.png
rm xubuntu-wallpaper.png
ln -sf kodi.png xubuntu-wallpaper.png
popd >& /dev/null
