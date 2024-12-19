#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs VirtualBox and extension pack on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install VirtualBox 7.0.14..."
#==============================================================================
# Set the debconf selection
apt-get install -y debconf-utils
echo virtualbox-ext-pack virtualbox-ext-pack/license select true | debconf-set-selections

# Add the Virtaulbox Repository and install it:
eval `cat /etc/os-release`
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian ${VERSION_CODENAME} contrib" > /etc/apt/sources.list.d/virtualbox.list
wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor
apt update
wget https://download.virtualbox.org/virtualbox/7.0.14/virtualbox-7.0_7.0.14-161095~Ubuntu~jammy_amd64.deb -O /tmp/virtualbox.deb
apt install -y /tmp/virtualbox.deb
apt-mark hold virtualbox-7.0

#==============================================================================
_title "Install VirtualBox 7.0.14 Extension Pack..."
#==============================================================================
wget https://download.virtualbox.org/virtualbox/7.0.14/Oracle_VM_VirtualBox_Extension_Pack-7.0.14.vbox-extpack -O /tmp/Oracle_VM_VirtualBox_Extension_Pack-7.0.14.vbox-extpack
VBoxManage extpack install --replace /tmp/Oracle_VM_VirtualBox_Extension_Pack-7.0.14.vbox-extpack --accept-license=33d7284dc4a0ece381196fda3cfe2ed0e1e8e7ed7f27b9a9ebc4ee22e24bd23c
