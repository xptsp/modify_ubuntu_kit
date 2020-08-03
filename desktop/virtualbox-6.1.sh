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
_title "Install VirtualBox..."
#==============================================================================
if [[ "$1" == "repo" ]]; then
	wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add -
	DIST=$(lsb_release -cs)
	[[ "${DIST}" == "focal" ]] && DIST=eoan
	echo "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian ${DIST} contrib" > /etc/apt/sources.list.d/virtualbox.list
	apt update
	apt install -y virtualbox-6.1
else
	wget https://download.virtualbox.org/virtualbox/6.1.6/virtualbox-6.1_6.1.6-137129~Ubuntu~bionic_amd64.deb -O /tmp/virtualbox.deb
	apt install -y /tmp/virtualbox.deb
	rm /tmp/virtualbox.deb
fi

# Third: Create finisher task:
#==============================================================================
add_taskd 75_virtualbox.sh

# Fourth: Add command to load virtualbox kernel modules:
#==============================================================================
[[ ! -f /etc/rc.local ]] && cat << EOF > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0
EOF
sed -i "s|^exit 0|# Initialize VirtualBox kernel modules:\n/sbin/vboxconfig\n\nexit 0|g" /etc/rc.local
chmod +x /etc/rc.local

#==============================================================================
_title "Installing VirtualBox Extension Pack..."
#==============================================================================
wget https://download.virtualbox.org/virtualbox/6.1.6/Oracle_VM_VirtualBox_Extension_Pack-6.1.6.vbox-extpack -O /tmp/Oracle_VM_VirtualBox_Extension_Pack-6.1.6.vbox-extpack
VBoxManage extpack install /tmp/Oracle_VM_VirtualBox_Extension_Pack-6.1.6.vbox-extpack --accept-license=56be48f923303c8cababb0bb4c478284b688ed23f16d775d729b89a2e8e5f9eb
rm /tmp/Oracle_VM_VirtualBox_Extension_Pack-6.1.6.vbox-extpack
