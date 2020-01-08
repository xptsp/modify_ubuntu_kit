#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# Defined directories:
IMG=/img
USB=${IMG}/usb
MNT=${IMG}/mnt
PTN2=${IMG}/extract-base
PTN3=${IMG}/extract-desktop
PTN4=${IMG}/extract-htpc
EXT=${IMG}/extract
ORG=${IMG}/original

# Abort if the RedDragon USB stick isn't found:
DEV=$(blkid | grep "RedDragon USB" | cut -d":" -f 1)
if [[ -z "${DEV}" ]]; then
	_error "USB stick with ${BLUE}RedDragon USB${GREEN} label was not detected!  Aborting!"
	exit 1
fi

# Mount the RedDragon USB stick:
_title "Mounting the RedDragon USB Stick...."
while [[ ! -z "$(mount | grep "${DEV}")" ]]; do umount ${DEV}; sleep 1; done
[[ ! -d ${USB} ]] && mkdir -p ${USB}
mount ${DEV} ${USB}

_title "Copy the Base edition to the USB stick..."
mount ${USB}/_ISO/MAINMENU/2* ${MNT}
cp ${PTN2}/casper/* ${MNT}/casper/
_title "Unmounting Base edition image partition..."
umount ${MNT}

_title "Copy the Desktop edition to the USB stick..."
mount ${USB}/_ISO/MAINMENU/3* ${MNT}
cp ${PTN3}/casper/* ${MNT}/casper/
_title "Unmounting Desktop edition image partition..."
umount ${MNT}

_title "Copy the HTPC edition to the USB stick..."
mount ${USB}/_ISO/MAINMENU/4* ${MNT}
cp ${PTN4}/casper/* ${MNT}/casper/
_title "Unmounting HTPC  edition image partition..."
umount ${MNT}

_title "Unmounting RedDragon USB stick..."
umount ${USB}
_title "Ejecting RedDragon USB stick..."
eject ${DEV}
_title "Done!"
