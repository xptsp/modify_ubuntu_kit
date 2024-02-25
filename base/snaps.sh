#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Downloads updated snaps for first-boot installation..."
	echo ""
	exit 0
fi

#==============================================================================
_title "Downloading updated snaps for first-boot installation..."
#==============================================================================
mkdir -p /var/lib/snapd/snaps.new
cd /var/lib/snapd/snaps.new
ls /var/lib/snapd/snaps/*.snap | grep -v firefox | while read FILE; do
	SNAP=$(basename ${FILE} | cut -d_ -f 1)
	CUR=$(basename ${FILE} | cut -d_ -f 2 | cut -d\. -f 1)
	UPD=$(snap list ${SNAP} | grep ${SNAP} | awk '{print $3}')
	[[ "${CUR}" != "${UPD}" ]] && snap download $SNAP
done
mkdir -p /usr/local/finisher/firstboot.d
ln -sf ${MUK_DIR}/files/tasks.d/98_snaps.sh /usr/local/finisher/firstboot.d/
