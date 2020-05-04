#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs VirtualBox 6.1 and extension pack on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install VirtualBox and VirtualBox Extension Pack..."
#==============================================================================
# First: Install the software :p
#==============================================================================
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add -
DIST=$(lsb_release -cs)
[[ "${DIST}" == "focal" ]] && DIST=eoan
echo "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian ${DIST} contrib" > /etc/apt/sources.list.d/virtualbox.list
apt update
sudo apt install virtualbox-6.1
