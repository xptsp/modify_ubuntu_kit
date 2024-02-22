#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Mozilla Firefox and Thunderbird on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Mozilla Firefox and Thunderbird..."
#==============================================================================
snap remove firefox
apt remove -y firefox
add-apt-repository -y ppa:mozillateam/ppa
cat << EOF > /etc/apt/preferences.d/mozillateamppa
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 501
EOF
apt update
apt install -y firefox thunderbird

#==============================================================================
_title "Copy launchers to the desktop and trust them..."
#==============================================================================
[[ ! -d ~/Desktop ]] && mkdir -p ~/Desktop
cp /usr/share/applications/firefox.desktop ~/Desktop/
dbus-launch --exit-with-session gio set ~/Desktop/firefox.desktop metadata::trusted true
chmod a+x ~/Desktop/firefox.desktop
cp /usr/share/applications/thunderbird.desktop ~/Desktop/
dbus-launch --exit-with-session gio set ~/Desktop/thunderbird.desktop metadata::trusted true
chmod a+x ~/Desktop/thunderbird.desktop
