#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Install DEB-version installation of Mozilla Firefox..."
	echo ""
	exit 0
fi
# Refuse to do this with the snap version of Firefox installed:
if apt list --installed firefox | grep -q 1:1snap1-0ubuntu2; then
	if [[ -f /var/lib/snapd/snaps/firefox_*.snap ]]; then 
		echo "ERROR: Snap version of Firefox is still present!"; exit 1;
	fi 
fi

#==============================================================================
_title "Installing DEB-version installation of Mozilla Firefox..."
#==============================================================================
add-apt-repository -y ppa:mozillateam/ppa
cat << EOF > /etc/apt/preferences.d/mozilla-team-ppa

Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox*
Pin: version *:1snap*
Pin-Priority: -1

Package: thunderbird*
Pin: version *:1snap*
Pin-Priority: -1
EOF
apt update
apt install --allow-change-held-packages --allow-downgrades -y firefox thunderbird 

#==============================================================================
_title "Copy launchers to the desktop and trust them..."
#==============================================================================
[[ ! -d ~/Desktop ]] && mkdir -p ~/Desktop
cp /usr/share/applications/firefox.desktop ~/Desktop/
dbus-launch --exit-with-session gio set ~/Desktop/firefox.desktop metadata::trusted true
chmod a+x ~/Desktop/firefox.desktop
dbus-launch --exit-with-session gio set ~/Desktop/firefox.desktop metadata::trusted true
cp /usr/share/applications/thunderbird.desktop ~/Desktop/
dbus-launch --exit-with-session gio set ~/Desktop/thunderbird.desktop metadata::trusted true
chmod a+x ~/Desktop/thunderbird.desktop
dbus-launch --exit-with-session gio set ~/Desktop/thunderbird.desktop metadata::trusted true
