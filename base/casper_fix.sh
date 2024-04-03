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
sed -i "/mount -t squashfs \| cut \-d\\\  \-f 3/d" ${FILE}
sed -i "/mount -o move \"\${d}\" \"\${rootmnt}\/rofs\"/,+2d" ${FILE}
sed -i "s|    mkdir -p \"\${rootmnt}/rofs\"|mkdir -p "\${rootmnt}/rofs"\n    mount -t overlay -o \"lowerdir=\$mounts\" overlay \"\${rootmnt}/rofs\"|" ${FILE}
update-initramfs -c -k all
