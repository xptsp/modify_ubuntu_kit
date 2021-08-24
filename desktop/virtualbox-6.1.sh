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
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add -
echo "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian ${OS_NAME} contrib" > /etc/apt/sources.list.d/virtualbox.list
apt update
apt install -y virtualbox-6.1

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

