#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Builds the NUC LED kernel module for your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install support software to control front LED panel..."
# Source: https://nucblog.net/2017/05/linux-kernel-driver-for-nuc-led-control/
#==============================================================================
# First: Install the software (duh... :p)
#==============================================================================
wget https://github.com/douglasorend/intel_nuc_led/releases/download/v2.0/intel-nuc-led-dkms_2.0_all.deb -O /tmp/intel-nuc-led-dkms_2.0_all.deb
apt install -y /tmp/intel-nuc-led-dkms_2.0_all.deb
rm /tmp/intel-nuc-led-dkms_2.0_all.deb

# Second: Make sure the WMI and the NUC LED modules get loaded:
#==============================================================================
cat << EOF > /etc/modules-load.d/nuc_led.conf
# Intel NUC LED kernel driver
wmi
nuc_led
EOF
chown root:root /etc/modules-load.d/nuc_led.conf

# Third: Configure the kernel module
#==============================================================================
echo "options nuc_led nuc_led_perms=0664 nuc_led_gid=100 nuc_led_uid=1000" > /etc/modprobe.d/nuc_led.conf
chown root:root /etc/modprobe.d/nuc_led.conf
