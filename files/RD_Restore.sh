#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

device=$(blkid | grep '/dev/sd' | grep "RedDragon USB")
if [[ ! -z "$device" ]]; then
	_title "Found RedDragon USB partition at ${BLUE}${device:0:9}${GREEN}!"
	exit 0
fi
device=$(blkid | grep '/dev/sd' | grep "RD Base")
[[ -z "$device" ]] && device=$(blkid | grep '/dev/sd' | grep "RD Desktop")
[[ -z "$device" ]] && device=$(blkid | grep '/dev/sd' | grep "RD HTPC")
if [[ -z "$device" ]]; then
	_error "No RedDragon USB drive detected!"
	exit 1
fi
DD="${device:0:8}"
_title "Found RedDragon USB drive at ${BLUE}${DD}${GREEN}!"
GOOD=0
dd if=$DD count=1 skip=60 2> /dev/null | grep 'helper' > /dev/null && GOOD=60
dd if=$DD count=1 skip=30 2> /dev/null | grep 'helper' > /dev/null && GOOD=30
dd if=$DD count=1 skip=0  2> /dev/null | grep 'helper' > /dev/null || GOOD=0
if [[ $GOOD == '0' ]] || [[ $GOOD == '' ]];  then
	_error "ERROR: NO BACKUP MBR FOUND IN LBA30 or LBA60 on ${BLUE}${DD}${GREEN}!"
	exit 2
else
	_title "Restoring MBR from backup found at sector $GOOD..."
	dd if=$DD of=$DD skip=$GOOD seek=0 count=1 2> /dev/null
	_title "Unmounting USB stick and resetting USB device..."
	if mount | grep ${device:0:9} >& /dev/null; then umount ${device:0:9}; fi
	usbreset ${DD}
fi
