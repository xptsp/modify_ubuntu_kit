#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Fixes issue with casper init script."
	echo ""
	exit 0
fi

#==============================================================================
_title "Fixing issue with casper init script..."
#==============================================================================
FILE=/usr/share/initramfs-tools/scripts/casper
sed -i.bak "s|panic \"overlay mount failed\"|panic \"overlay mount failed\"\n    mkdir -p \"\$rootmnt/rofs\"\n    mount -t overlay -o \"lowerdir=\$mounts\" \"/rofs\" \"\$rootmnt/rofs\"|" ${FILE}
sed -i "/# move the first mount; no head in busybox-initramfs/,+5d" ${FILE}
update-initramfs -c -k all
