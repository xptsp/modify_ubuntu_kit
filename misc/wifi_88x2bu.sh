#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Kernel driver for 88x2bu chipset."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install Kernel driver for 88x2bu chipset..."
#==============================================================================
# First: Install Pre-requisites:
apt install -y linux-headers-$(uname -r) build-essential bc dkms git libelf-dev rfkill iw

# Second: Get the source for the driver and install it: 
git clone https://github.com/morrownr/88x2bu-20210702 /opt/88x2bu-20210702
cd /opt/88x2bu-20210702
./install-driver.sh NoPrompt

# Third: Turn off annoying LED on the stick:
sed -i "s|rtw_led_ctrl=1|rtw_led_ctrl=0|g" /etc/modprobe.d/88x2bu.conf
