#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs DropBox on your computer...."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing DropBox core software...."
#==============================================================================
# First: Get the software:
#==============================================================================
wget https://www.dropbox.com/download?plat=lnx.x86_64 -O /tmp/dropbox-linux-x86_64.tar.gz
mkdir /opt/dropbox
tar xzfv /tmp/dropbox-linux-x86_64.tar.gz --strip 1 -C /opt/dropbox
rm /tmp/dropbox-linux-x86_64.tar.gz

# Second: Get and configure the service file:
#==============================================================================
wget https://gist.githubusercontent.com/thisismitch/d0133d91452585ae2adc/raw/699e7909bdae922201b8069fde3011bbf2062048/dropbox -O /etc/init.d/dropbox
chmod 755 /etc/init.d/dropbox
DROPBOX_USERS=$(grep ":1000:" /etc/passwd | cut -d: -f 1)
echo 'DROPBOX_USERS="${DROPBOX_USERS:-"kodi"}"' > /etc/default/dropbox
change_username /etc/default/dropbox

# Third: Get the dropbox binary:
#==============================================================================
wget https://www.dropbox.com/download?dl=packages/dropbox.py -O /usr/local/bin/dropbox
chmod 555 /usr/local/bin/dropbox
ln -sf /opt/dropbox ~/.dropbox-dist

#==============================================================================
# Fourth: Get Dropbox integration with Thunar --ONLY-- if thunar is installed:
#==============================================================================
apt list --list-installed thunar 2> /dev/null | grep -q thunar && _title "Installing DropBox extension for Thunar...." && apt install -y thunar-dropbox-plugin
apt list --list-installed nautilus 2> /dev/null | grep -q nautilus && _title "Installing DropBox extension for Nautilus...." && apt install -y nautilus-dropbox
