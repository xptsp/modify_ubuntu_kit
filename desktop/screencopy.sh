#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs ScreenCopy (scrcpy) and ScreenCopy GUI (scrcpy-gui) on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Get ScrCpy dependencies..."
#==============================================================================
apt install -y adb ffmpeg libsdl2-2.0.0 make gcc pkg-config meson ninja-build libavcodec-dev libavformat-dev libavutil-dev libsdl2-dev fastboot

#==============================================================================
_title "Compile ScrCpy for Ubuntu..."
#==============================================================================
wget https://github.com/Genymobile/scrcpy/releases/download/v1.11/scrcpy-server-v1.11 -O /tmp/scrcpy-server-v1.11.jar
wget https://github.com/Genymobile/scrcpy/archive/v1.11.tar.gz -O /tmp/v1.11.tar.gz
pushd /tmp
tar xfv v1.11.tar.gz
rm v1.11.tar.gz
cd scrcpy-1.11
meson build --buildtype release --strip -Db_lto=true  -Dprebuilt_server=../scrcpy-server-v1.11.jar
cd build
ninja
ninja install
cd ../..
rm -rf scrcpy-1.11
rm scrcpy-server-v1.11.jar
popd

#==============================================================================
_title "Install ScrCpy GUI for Ubuntu..."
#==============================================================================
wget https://github.com/Tomotoes/scrcpy-gui/releases/download/1.0.0/ScrcpyGui-1.0.0.deb -O /tmp/ScrcpyGui-1.0.0.deb
apt install -y /tmp/ScrcpyGui-1.0.0.deb
rm /tmp/ScrcpyGui-1.0.0.deb
