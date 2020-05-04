#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Remmina on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Remmina...."
#==============================================================================
# First: Install dependencies:
#==============================================================================
apt install -y build-essential git-core cmake libssl-dev libx11-dev libxext-dev libxinerama-dev \
  libxcursor-dev libxdamage-dev libxv-dev libxkbfile-dev libasound2-dev libcups2-dev libxml2 libxml2-dev \
  libxrandr-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libxi-dev libavutil-dev \
  libavcodec-dev libxtst-dev libgtk-3-dev libgcrypt20-dev libssh-dev libpulse-dev \
  libvte-2.91-dev libxkbfile-dev libtelepathy-glib-dev libjpeg-dev \
  libgnutls28-dev libavahi-ui-gtk3-dev libvncserver-dev \
  libappindicator3-dev intltool libsecret-1-dev libwebkit2gtk-4.0-dev libsystemd-dev \
  libsoup2.4-dev libjson-glib-dev libavresample-dev libsodium-dev \
  libusb-1.0-0-dev

# Second: Remove any installed copies of Remmina:
#==============================================================================
apt -y purge "?name(^remmina.*)" "?name(^libfreerdp.*)" "?name(^freerdp.*)" "?name(^libwinpr.*)"

# Third: Compile the FreeRDP-x11 package:
#==============================================================================
mkdir /root/remmina_devel
cd /root/remmina_devel
git clone --branch stable-2.0 https://github.com/FreeRDP/FreeRDP.git
cd FreeRDP
cmake -DCMAKE_BUILD_TYPE=Debug -DWITH_SSE2=ON -DWITH_CUPS=on -DWITH_PULSE=on -DCMAKE_INSTALL_PREFIX:PATH=/opt/remmina_devel/freerdp .
make && make install
echo /opt/remmina_devel/freerdp/lib > /etc/ld.so.conf.d/freerdp_devel.conf
ldconfig
ln -s /opt/remmina_devel/freerdp/bin/xfreerdp /usr/local/bin/

# Fourth: Compile the remmina package:
#==============================================================================
cd /root/remmina_devel
git clone https://gitlab.com/Remmina/Remmina.git
cd Remmina
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX:PATH=/opt/remmina_devel/remmina -DCMAKE_PREFIX_PATH=/opt/remmina_devel/freerdp --build=build .
make && make install
ln -s /opt/remmina_devel/remmina/bin/remmina /usr/local/bin/

# Fifth: Pull the "script.kodi.launches.emulationstation" addon:
#==============================================================================
### First: Get the repo:
git clone --depth=1 https://github.com/xptsp/script.kodi.launches.remmina ${KODI_OPT}/script.kodi.launches.remmina
### Second: Link the repo:
ln -sf ${KODI_OPT}/script.kodi.launches.remmina ${KODI_ADD}/script.kodi.launches.remmina
### Third: Enable addon by default:
kodi_enable script.kodi.launches.remmina
