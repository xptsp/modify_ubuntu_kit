#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Holds kernel so LiveCD boots up."
	echo ""
	exit 0
fi

#==============================================================================
_title "Holding kernel update so LiveCD boots up:"
#==============================================================================
apt-mark hold linux-headers-5.11.0-27-generic
apt-mark hold linux-hwe-5.11-headers-5.11.0-27
apt-mark hold linux-image-5.11.0-27-generic
apt-mark hold linux-modules-5.11.0-27-generic
apt-mark hold linux-modules-extra-5.11.0-27-generic
add_taskd 98_unhold_kernel.sh