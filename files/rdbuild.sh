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

# Unpack the factory XUbuntu 18.04.3 ISO so we can play with it:
if [[ ! -d ${ORG} ]]; then
	# Abort if the RedDragon USB stick isn't found:
	DEV=$(blkid | grep "RedDragon USB" | cut -d":" -f 1)
	if [[ -z "${DEV}" ]]; then
		_error "USB stick with ${BLUE}RedDragon USB${GREEN} label was not detected!  Aborting!"
		exit 1
	fi

	# Mount the RedDragon USB stick:
	while [[ ! -z "$(mount | grep "${DEV}")" ]]; do umount ${DEV}; sleep 1; done
	[[ ! -d ${USB} ]] && mkdir -p ${USB}
	mount ${DEV} ${USB}

	# Unpack the factory Xubuntu 18.04 ISO image:
	[[ ! -d ${MNT} ]] && mkdir -p ${MNT}
	edit_chroot unpack-full ${USB}/_ISO/MAINMENU/1*.iso
	mv ${EXT} ${ORG}
	ln -sf ${ORG} ${EXT}

	# Unmount the factory Xubuntu 18.04 ISO:
	umount ${USB}
else
	[[ -d ${EXT} ]] && rm -rf ${EXT} || rm ${EXT}
	ln -sf ${ORG} ${EXT}
	edit_chroot unpack
fi

# Create our "base" install:
[[ -f ${PTN2} ]] && rm -rf ${PTN2}
cp -R ${ORG} ${PTN2}
rm ${EXT}
ln -sf ${PTN2} ${EXT}
edit_chroot build base
edit_chroot rebuild

# Create our "desktop" install:
[[ -f ${PTN3} ]] && rm -rf ${PTN3}
cp -R ${ORG} ${PTN3}
rm ${EXT}
ln -sf ${PTN3} ${EXT}
edit_chroot build desktop
edit_chroot rebuild

# Create our "htpc" install:
[[ -f ${PTN4} ]] && rm -rf ${PTN4}
cp -R ${ORG} ${PTN4}
rm ${EXT}
ln -sf ${PTN4} ${EXT}
edit_chroot build htpc
edit_chroot rebuild
