#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs X11Docker and Openbox."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing X11Docker...."
#==============================================================================
curl -fsSL https://raw.githubusercontent.com/mviereck/x11docker/master/x11docker | bash -s -- --update

#==============================================================================
_title "Installing X11Docker...."
#==============================================================================
### First: Build the package, then install it:
git clone https://github.com/xptsp/x11docker-openbox /tmp/x11docker-openbox
cd /tmp/x11docker-openbox
./build.sh
apt install -y ./x11docker-openbox.deb
### Second: Remove the openbox option, since it just gives a blank screen:
rm /usr/share/xsessions/openbox.desktop
