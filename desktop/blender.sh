#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs FFMPEG and Blender 3D on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install Blender 3D..."
#==============================================================================
wget https://mirror.clarkson.edu/blender/release/Blender3.0/blender-3.0.1-linux-x64.tar.xz -O /tmp/blender-3.0.1-linux-x64.tar.xz
cd /opt
tar -vxf /tmp/blender-3.0.1-linux-x64.tar.xz
FILE=/usr/share/applications/blender.desktop
cp blender-3.0.1-linux-x64/blender.desktop ${FILE}
sed -i "s|Exec=blender|Exec=$PWD/blender|g" ${FILE}
sed -i "s|Icon=blender|Icon=$PWD/blender.svg|g" ${FILE}
