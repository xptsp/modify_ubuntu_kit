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
_title "Checking kernel version:"
#==============================================================================
KERN_VER=$(apt list --installed linux-image* 2> /dev/null | grep linux-image | head -1 | cut -d- -f 3)
if [[ $(echo $KERN_VER | cut -d. -f 1)$(echo $KERN_VER | cut -d. -f 2) -eq 511 ]]; then
	#==============================================================================
	_title "Holding kernel version so LiveCD boots up:"
	#==============================================================================
	for PACKAGE in $(apt list --installed *${KERN_VER}* 2> /dev/null | cut -d/ -f 1); do 
		[[ "$PACKAGE" != "Listing..." ]] && apt-mark hold $PACKAGE
	done
fi
add_taskd 98_unhold_kernel.sh
