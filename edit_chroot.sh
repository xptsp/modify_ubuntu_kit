#!/bin/bash

#==============================================================================
# Script settings and their defaults:
#==============================================================================
# If exists, load the user settings into the script:
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
# Flag: Defaults to adding date ISO was generated to end of ISO name.  Set to 0 to prevent this.
export FLAG_ADD_DATE=${FLAG_ADD_DATE:-"1"}
# Flag: Use XZ (value: 1) instead of GZIP (value: 0) compression.  Defaults to 0:
export FLAG_XZ=${FLAG_XZ:-"0"}
# Flag: Use MKIFOFS (value: 1) instead of GENISOIMAGE (value: 0).  Defaults to 0.
export FLAG_MKISOFS=${FLAG_MKISOFS:-"0"}
# Where to place extracted and chroot environment directories.  Defaults to "/img".
export UNPACK_DIR=${UNPACK_DIR:-"/home/img"}
# Where to place the generated ISO file.  Defaults to current directory.
export ISO_DIR=${ISO_DIR:-"${UNPACK_DIR}"}
# Default to removing old kernels from chroot environment.  Set to 0 to prevent this.
export OLD_KERNEL=${OLD_KERNEL:-"1"}
# Determine ISO version number to use:
[[ -f ${UNPACK_DIR}/edit/etc/os-release ]] && export ISO_VERSION=$(cat ${UNPACK_DIR}/edit/etc/os-release | grep "VERSION=" | cut -d "\"" -f 2 | cut -d " " -f 1)
# MUK path:
export MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
# Custom USB Stick partition #1 identification:
export USB_LIVE=${USB_LIVE:-"LABEL=\"UBUNTU_LIVE\""}
export USB_LIVE=$(echo ${USB_LIVE} | cut -d= -f 1)=\"$(echo ${USB_LIVE} | cut -d= -f 2 | sed "s|\"||g")\"
# Custom USB Stick partition #2 identification:
export USB_CASPER=${USB_CASPER:-"LABEL=\"UBUNTU_CASPER\""}
echo ${USB_CASPER} | grep -q "=" && export USB_CASPER=$(echo ${USB_CASPER} | cut -d= -f 1)=\"$(echo ${USB_CASPER} | cut -d= -f 2 | sed "s|\"||g")\"

#==============================================================================
# Get the necessary functions in order to function correctly:
#==============================================================================
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

#==============================================================================
# If no help is requested, make sure script is running as root and needed
# packages have been installed on this computer.
#==============================================================================
if ! [[ -z "$1" || "$1" == "--help" ]]; then
	# Make sure we got everything we need to create a customized Ubuntu disc:
	MKSQUASH=$(whereis mksquashfs | cut -d ":" -f 2 | cut -d " " -f 2)
	GENISO=$(whereis genisoimage | cut -d ":" -f 2 | cut -d " " -f 2)
	GIT=$(whereis git | cut -d ":" -f 2 | cut -d " " -f 2)
	XOR=$(whereis xorriso | cut -d ":" -f 2 | cut -d " " -f 2)
	if [[ -z $MKSQUASH || -z $GENISO || -z $GIT ]]; then
		_title "Installing necessary packages..."
		apt-get update >& /dev/null
		apt-get install -y $([[ -z $MKSQUASH ]] && echo "squashfs-tools") $([[ -z $GENISO ]] && echo "genisoimage") $([[ -z $GIT ]] && echo "git")
		if [[ -z "${XOR}" ]]; then apt list xorriso 2> /dev/null | grep -q xorriso && apt-get install -y xorriso; fi
	fi
fi

#==============================================================================
# Did user request to safely unmount the filesystem mount points?
#==============================================================================
if [[ "$1" == "update" ]]; then
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_error "Cannot use ${BLUE}update${GREEN} inside chroot environment!"
		exit 1
	elif [[ ! -d ${MUK_DIR}/.git ]]; then
		_error "Unable to update the toolkit because it is not a GitHub repository!"
		exit 1
	fi
	_title "Fetching latest version of this script"
	if [ ! -d ${MUK_DIR} ]; then
		git clone --depth=1 https://github.com/xptsp/modify_ubuntu_kit ${MUK_DIR}
	else
		cd ${MUK_DIR}
		git reset --hard
		git pull
	fi
	[[ -f ${MUK_DIR}/install.sh ]] && ${MUK_DIR}/install.sh
	_title "Script has been updated to latest version."
	exit 0

#==============================================================================
# Are we changing the unpacked CHROOT environment?
#==============================================================================
elif [[ "$1" == "mount" ]]; then
	if [[ ! -f ${UNPACK_DIR}/extract/casper/filesystem.squashfs ]]; then
		_error "No \"filesystem.squashfs\" found!  Use ${BLUE}edit_chroot unpack${GREEN} first!"
		exit 1
	fi
	mount | grep -q "${UNPACK_DIR}/edit " && umount edit
	mount | grep "${UNPACK}/.lower" | awk '{print $3}' | while read DIR; do umount -lfq ${DIR}; rmdir ${DIR}; done
	mkdir -p ${UNPACK_DIR}/{.lower,.upper,.work,edit}
	mount ${UNPACK_DIR}/extract/casper/filesystem.squashfs ${UNPACK_DIR}/.lower || exit 1
	COUNT=0
	TLOWER=${UNPACK_DIR}/.lower$(ls ${UNPACK_DIR}/extract/casper/filesystem_*.squashfs 2> /dev/null | while read FILE; do
		COUNT=$((COUNT + 1))
		mkdir -p ${UNPACK_DIR}/.lower${COUNT}
		mount ${FILE} ${UNPACK_DIR}/.lower${COUNT} || exit 1
		echo -n ":${UNPACK_DIR}/.lower${COUNT}"
	done)
	TLOWER=($(echo $TLOWER | sed "s|\:|\n|g" | tac))
	LOWER=$(echo ${TLOWER[@]} | sed "s| |:|g")
	mount -t overlay -o lowerdir=${LOWER},upperdir=${UNPACK_DIR}/.upper,workdir=${UNPACK_DIR}/.work overlay ${UNPACK_DIR}/edit || exit 1
	_title "Necessary chroot filesystem mount points have been mounted!"

#==============================================================================
# Are we changing the unpacked CHROOT environment?
#==============================================================================
elif [[ "$1" == "enter" || "$1" == "upgrade" || "$1" == "build" ]]; then
	#==========================================================================
	# Determine if we are working inside or outside the CHROOT environment
	#==========================================================================
	if [[ $(ischroot; echo $?) -eq 1 ]]; then
		#======================================================================
		# RESULT: We are outside the chroot environment:
		#======================================================================
		### First: Make sure that the CHROOT environment actually exists:
		if [[ "$1" == "build" ]]; then
			if [[ ! "$2" == "base" && ! "$2" == "desktop" && ! "$2" == "htpc" && ! "$2" == "docker" ]]; then
				_error "Invalid parameter!  Supported values are: ${RED}base${GREEN}, ${RED}desktop${GREEN}, ${RED}htpc${GREEN} and ${RED}docker${GREEN}!"
				exit 1
			fi
		fi

		### Second: Update MUK, then setup the CHROOT environment:
		cd ${UNPACK_DIR}
		$0 unmount
		$0 mount || exit 1
		cp /etc/resolv.conf ${UNPACK_DIR}/edit/etc/
		cp /etc/hosts ${UNPACK_DIR}/edit/etc/
		mount --bind /run/ ${UNPACK_DIR}/edit/run
		mount --bind /dev/ ${UNPACK_DIR}/edit/dev
		mount -t tmpfs tmpfs ${UNPACK_DIR}/edit/tmp

		### Third: Copy MUK into chroot environment:
		rm -rf ${UNPACK_DIR}/edit/${MUK_DIR}
		cp -aR ${MUK_DIR} ${UNPACK_DIR}/edit/${MUK_DIR}
		chown root:root -R ${UNPACK_DIR}/edit/${MUK_DIR}

		### Fourth: Enter the CHROOT environment:
		_title "Entering CHROOT environment"
		chroot ${UNPACK_DIR}/edit ${MUK_DIR}/edit_chroot.sh $@
		[[ -f ${UNPACK_DIR}/edit/usr/local/finisher/build.txt ]] && cp ${UNPACK_DIR}/edit/usr/local/finisher/build.txt ${UNPACK_DIR}/extract/casper/build.txt

		### Fifth: Run required commands outside chroot commands:
		if [[ -f ${UNPACK_DIR}/edit/usr/local/finisher/outside_chroot.list ]]; then
			$0 docker_mount
			_title "Executing scripts outside of CHROOT environment..."
			(while read p; do ${UNPACK_DIR}/edit/$p; done) < ${UNPACK_DIR}/edit/usr/local/finisher/outside_chroot.list
			$0 docker_umount
		fi

		### Thirteenth: Copy the new INITRD from the unpacked filesystem:
		cd ${UNPACK_DIR}/edit
		INITRD=$(ls initrd.img-* 2> /dev/null | sort -r | head -1)
		[[ -z "${INITRD}" ]] && INITRD_SRC=$(ls boot/initrd.img-* 2> /dev/null | sort -r | head -1)
		if [[ ! -z "${INITRD_SRC}" ]]; then
			_title "Moving INITRD.IMG from unpacked filesystem from ${BLUE}${INITRD_SRC}${GREEN}..."
			mv ${UNPACK_DIR}/edit/${INITRD_SRC} ${UNPACK_DIR}/extract/casper/initrd
			sed -i "s|initrd.gz|initrd|g" ${UNPACK_DIR}/extract/boot/grub/grub.cfg
		fi

		### Fourteenth: Copy the new VMLINUZ from the unpacked filesystem:
		VMLINUZ=$(ls vmlinuz-* 2> /dev/null | sort -r | head -1)
		[[ -z "${VMLINUZ}" ]] && VMLINUZ=$(ls boot/vmlinuz-* 2> /dev/null | sort -r | head -1)
		if [[ ! -z "${VMLINUZ}" ]]; then
			_title "Moving VMLINUZ from unpacked filesystem from ${BLUE}${VMLINUZ}${GREEN}...."
			mv ${UNPACK_DIR}/edit/${VMLINUZ} ${UNPACK_DIR}/extract/casper/vmlinuz
		fi

		### Sixth: Remove mounts for CHROOT environment:
		cd ${UNPACK_DIR}
		$0 unmount
		_title "Exited CHROOT environment"
	else
		#======================================================================
		# RESULT: We are inside the chroot environment....
		#======================================================================
		### First: Set the remaining stuff
		mount -t proc none /proc
		mount -t sysfs none /sys
		mount -t devpts none /dev/pts
		export HOME=/etc/skel
		export LC_ALL=C
		dbus-uuidgen > /var/lib/dbus/machine-id
		dpkg-divert --local --rename --add /sbin/initctl >& /dev/null
		ln -sf /bin/true /sbin/initctl
		export PASSWORD=xubuntu
		export DEBIAN_FRONTEND=noninteractive
		export USER=root
		export SUDO_USER=root
		export KODI_OPT=/opt/kodi
		export KODI_ADD=/etc/skel/.kodi/addons
		export KODI_BASE=http://mirrors.kodi.tv/addons/leia/

		### Second: Install the chroot tools if required, then put firefox on hold if it is still snap version:
		${MUK_DIR}/install.sh
		if ! apt-mark showhold | grep -q firefox; then apt list --installed firefox 2> /dev/null | grep -q 1snap1 && apt-mark hold firefox > /dev/null; fi
		test -e /usr/local/bin/cls || ln -sf /usr/bin/clear /usr/local/bin/cls

		### Third: Next action depends on parameter passed....
		if [[ "$1" == "enter" ]]; then
			### "enter": Create a bash shell for user to make alterations to chroot environment
			clear
			_title "Ready to modify CHROOT environment!"
			echo -e "${RED}NOTE: ${GREEN}Enter ${BLUE}exit${GREEN} to exit the CHROOT environment"
			echo -e ""
			echo "CHROOT" > /etc/debian_chroot
			echo ". ${MUK_DIR}/files/includes.sh" >> /etc/skel/.bashrc
			bash -s
			cat /etc/skel/.bashrc | grep -v "${MUK_DIR}/files/includes.sh" > /tmp/.bashrc
			mv /tmp/.bashrc /etc/skel/.bashrc
			[ -f /etc/debian_chroot ] && rm /etc/debian_chroot
			clear
		elif [[ "$1" == "build" ]]; then
			### "build": Install all scripts found in the specified build folder:
			cd ${MUK_DIR}/$2
			for file in *.sh; do ./$file; done
		fi

		### Fourth: If user 999 exists, change that user ID so that LiveCD works:
		if [[ "$(id -u 999 >& /dev/null; echo $?)" -eq 0 ]]; then
			uid_name=$(id -un 999)
			uid_new=998
			while [ "$(id -u ${uid_new} >& /dev/null; echo $?)" -eq 0 ]; do uid_new=$((uid_new-1)); done
			_title "Changing user \"${uid_name}\" from UID 999 to ${uid_new} so LiveCD works..."
			usermod -u ${uid_new} ${uid_name}
			chown -Rhc --from=999 ${uid_new} / >& /dev/null
		fi

		### Fifth: If group 999 exists, change that group ID so that LiveCD works:
		gid_line=$(getent group 999)
		if [[ ! -z "${gid_line}" ]]; then
			gid_name=$(echo $gid_line | cut -d":" -f 1)
			gid_new=998
			while [ "$(getent group ${gid_new} >& /dev/null; echo $?)" -eq 0 ]; do gid_new=$((gid_new-1)); done
			_title "Changing group \"${gid_name}\" from GID 999 to ${gid_new} so LiveCD works..."
			groupmod -g ${gid_new} ${gid_name}
			chown -Rhc --from=:999 :${gid_new} / >& /dev/null
		fi

		### Sixth: Upgrade the installed GitHub repositories:
		_title "Updating GitHub repositories in ${BLUE}/opt${GREEN}..."
		cd /opt
		(ls | while read p; do pushd $p; [ -d .git ] && git pull; popd; done) >& /dev/null

		### Seventh: Upgrade the pre-installed Kodi addons via GitHub repositories:
		if [ -d /opt/kodi ]; then
			_title "Updating Kodi addons from GitHub repositories in ${BLUE}/opt/kodi${GREEN}...."
			pushd /opt/kodi >& /dev/null
			(ls | while read p; do pushd $p; [ -d .git ] && git pull; popd; done) >& /dev/null
			popd >& /dev/null
		fi

		### Eighth: Update packages:
		_title "Updating repository lists...."
		apt-get update >& /dev/null
		_title "Upgrading any packages requiring upgrading..."
		apt-get upgrade -y

		### Ninth: Purge older kernels from the image:
		if [[ "${OLD_KERNEL}" -eq 1 ]]; then
			_title "Removing any older kernels from the image..."
			CUR=$(ls -l /boot/initrd.img | awk '{print $NF}' | sed "s|initrd.img-||" | sed "s|-generic||")
			for VER in $(apt list linux-image-* --installed 2> /dev/null | grep linux-image | cut -d/ -f 1 | grep -o -e "[0-9]*\.[0-9]*\.[0-9]*\-[0-9]*"); do
				[[ "$VER" != "${CUR}" ]] && apt purge -y $(apt list --installed linux-*${VER}* 2> /dev/null | grep linux- | cut -d\/ -f 1)
			done
		fi

		### Tenth: Remove any unnecessary packages and fix any broken packages:
		_title "Removing unnecessary packages and fixing any broken packages..."
		apt-get install -f --autoremove --purge -y

		### Eleventh: Remove any unnecessary packages:
		_title "Cleaning up cached packages..."
		apt-get autoclean -y >& /dev/null
		apt-get clean -y >& /dev/null

		### Twelveth: Disable services not required during Live ISO:
		if [[ -f /usr/local/finisher/disabled.list ]]; then
			_title "Disabling unnecessary services for Live CD..."
			(while read p r; do systemctl disable $p; done) < /usr/local/finisher/disabled.list >& /dev/null
		fi

		### Fifteenth: Clean up everything done to "chroot" into this ISO image:
		_title "Undoing CHROOT environment modifications..."
		if apt-mark showhold | grep -q firefox; then apt list firefox 2> /dev/null | grep -q 1snap1 && apt-mark unhold firefox > /dev/null; fi
		chmod 440 /etc/sudoers.d/*
		rm -rf /tmp/* ~/.bash_history
		rm /var/lib/dbus/machine-id
		rm /sbin/initctl
		dpkg-divert --rename --remove /sbin/initctl >& /dev/null
		umount -lfq /tmp 2> /dev/null
		umount -lfq /proc 2> /dev/null
		umount -lfq /sys 2> /dev/null
		umount -lfq /dev/pts 2> /dev/null
		exit 0
	fi

#==============================================================================
# Did user request to safely unmount the filesystem mount points?
#==============================================================================
elif [[ "$1" == "unmount" ]]; then
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_error "Cannot use ${BLUE}unmount${GREEN} inside chroot environment!"
		exit 1
	fi
	_title "Unmounting filesystem mount points...."
	umount -qlf ${UNPACK_DIR}/edit/tmp/host >& /dev/null
	mount | grep "${UNPACK_DIR}/edit" | awk '{print $3}' | tac | while read DIR; do umount -qlf ${DIR}; done
	mount | grep "${UNPACK_DIR}/.lower" | awk '{print $3}' | while read DIR; do umount -qlf ${DIR}; rmdir ${DIR}; done
	$0 docker_umount -q
	_title "All filesystem mount points should be unmounted now."

#==============================================================================
# Did user request to safely remove the unpacked filesystem?
#==============================================================================
elif [[ "$1" == "remove" ]]; then
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_error "Cannot use ${BLUE}remove${GREEN} inside chroot environment!"
		exit 1
	elif [[ ! -d ${UNPACK_DIR}/edit ]]; then
		_error "No unpacked filesystem!  Use ${BLUE}edit_chroot unpack${GREEN} first!"
		exit 1
	fi
	$0 unmount
	_title "Removing modifications to squashfs..."
	umount -q ${UNPACK_DIR}/edit
	rm -rf ${UNPACK_DIR}/.upper
	_title "Modifications to squashfs filesystem has been removed."

#==============================================================================
# Did user request to unpack the ISO?
#==============================================================================
elif [[ "$1" == "unpack" ]]; then
	# First: Make sure everything is okay before proceeding:
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_error "Cannot use ${BLUE}unpack${GREEN} inside chroot environment!"
		exit 1
	fi
	cd ${UNPACK_DIR}
	mkdir -p mnt
	umount -q mnt
	ISO=$2
	if [[ -z "$ISO" ]]; then
		if mount /dev/cdrom ${UNPACK_DIR}/mnt; then
			_error "No DVD in the drive!"
			exit 1
		fi
	else
		if ! mount -o loop $ISO ${UNPACK_DIR}/mnt >& /dev/null; then
			_error "Specified ISO unable to be mounted!"
			exit 1
		fi
	fi
	if [[ ! -f mnt/casper/filesystem.squashfs ]]; then
		_error "Cannot find a ${BLUE}filesystem.squashfs${GREEN} to extract!!!"
		exit 1
	fi

	# Second: Copy the necessary files to the hard drive:
	_title "Found ${BLUE}filesystem.squashfs${GREEN} in ${BLUE}${UNPACK_DIR}/${MNT}${GREEN}!!!"
	_title "Removing folder ${BLUE}edit${GREEN} for clean extraction..."
	$0 remove
	_title "Copying contents of ISO..."
	mkdir -p extract
	rsync -a mnt/ extract

	# Third: Unmount the DVD/ISO if necessary:
	_title "Unmounting DVD/ISO from mount point...."
	umount -q mnt

	# Fourth: Tell user we done!
	_title "Ubuntu ISO unpacked!"

#==============================================================================
# Did user request to pack the chroot environment?
#==============================================================================
elif [[ "$1" == "pack" || "$1" == "pack-xz" || "$1" == "changes" || "$1" == "changes-xz" ]]; then
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_error "Cannot use ${BLUE}pack${GREEN} inside chroot environment!"
		exit 1
	elif [[ ! -d ${UNPACK_DIR}/extract ]]; then
		_error "No ISO structure created!  Use ${BLUE}edit_chroot unpack${GREEN} first!"
		exit 1
	elif [[ ! -d ${UNPACK_DIR}/edit ]]; then
		_error "No unpacked filesystem!  Use ${BLUE}edit_chroot unpack${GREEN} first!"
		exit 1
	fi

	# First: Prep the unpacked filesystem to be packaged:
	cd ${UNPACK_DIR}
	$0 unmount
	$0 mount || exit 1
	[ -f ${UNPACK_DIR}/edit/etc/debian_chroot ] && rm ${UNPACK_DIR}/edit/etc/debian_chroot
	rm -rf ${UNPACK_DIR}/edit${MUK_DIR}
	cp -R ${MUK_DIR} ${UNPACK_DIR}/edit/opt/

	# Second: Build the list of installed packages in unpacked filesystem:
	cd ${UNPACK_DIR}
	_title "Building list of installed packages...."
	chmod +w extract/casper/filesystem.manifest >& /dev/null
	chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' | tee extract/casper/filesystem.manifest >& /dev/null
	sed -i '/ubiquity/d' extract/casper/filesystem.manifest
	sed -i '/casper/d' extract/casper/filesystem.manifest

	# Third: Set necessary flags for compression:
	[[ "$1" =~ -xz$ ]] && FLAG_XZ=1
	XZ=$([[ ${FLAG_XZ:-"0"} == "1" ]] && echo "-comp xz -Xdict-size 100%")

	# Fourth: Pack the filesystem-opt.squashfs if required:
	FS=filesystem_$(date +"%Y%m%d")
	if [[ -f extract/casper/${FS}.squashfs ]]; then
		ISO_FILE=${FS}-$(( $(ls ${FS}-* | sed "s|${FS}-||" | sed "s|\.squashfs||" | sort -n | tail -1) + 1 ))
	fi
	FS=${FS}.squashfs
	_title "Building ${BLUE}${FS}${GREEN}...."
	[[ "$1" == "pack" || "$1" == "pack-xz" ]] && SRC=edit || SRC=.upper
	mksquashfs ${SRC} extract/casper/${FS} -b 1048576 ${XZ}

	# Fifth: If "KEEP_CIFS" flag is set, remove the "cifs-utils" package from the list of stuff to
	[[ "${KEEP_CIFS:-"0"}" == "1" && -f extract/casper/filesystem.manifest-remove ]] && sed -i '/cifs-utils/d' extract/casper/filesystem.manifest-remove

	# Sixth: Create the "filesystem.size" file:
	_title "Updating ${BLUE}filesystem.size${GREEN}...."
	du -s --block-size=1 edit | cut -f1 > extract/casper/filesystem.size

	# Seventh: remove the overlay filesystem and upper layer of overlay, then create the "md5sum.txt" file:
	_title "Removing the overlay filesystem and upper layer of overlay..."
	umount -q ${UNPACK_DIR}/edit
	for DIR in ${UNPACK_DIR}/.lower*; do umount -q ${DIR}; rmdir ${DIR}; done
	if [[ "$1" == "pack" || "$1" == "pack-xz" ]]; then
		mv ${UNPACK_DIR}/extract/casper/${FS} ${UNPACK_DIR}/extract/casper/filesystem.squashfs
		rm ${UNPACK_DIR}/extract/casper/filesystem_*.squashfs 2> /dev/null
	fi
	rm -rf .upper
	[[ -f /tmp/exclude ]] && rm /tmp/exclude
	_title "Creating the "md5sum.txt" file..."
	cd extract
	[ -f md5sum.txt ] && rm md5sum.txt
	find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.txt >& /dev/null

	# Eighth: Tell user we done!
	_title "Done packing and preparing extracted filesystem!"

#==============================================================================
# Did user request to create the ISO?
#==============================================================================
elif [[ "$1" == "iso" ]]; then
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_error "Cannot use ${BLUE}iso${GREEN} inside chroot environment!"
		exit 1
	elif [[ ! -d ${UNPACK_DIR}/extract ]]; then
		_error "No ISO structure copied!  Use ${BLUE}edit_chroot unpack${GREEN} first!"
		exit 1
	elif [[ ! -f ${UNPACK_DIR}/extract/casper/filesystem.squashfs ]]; then
		_error "No packed filesystem!  Use ${BLUE}edit_chroot pack${GREEN} first!"
		exit 1
	fi

	# First: Read either the OS's "build.txt" file OR the "os-release":
	ISO_DIR=${UNPACK_DIR}
	unset MUK_BUILD
	if [[ -f ${UNPACK_DIR}/edit/etc/os-release ]]; then
		source ${UNPACK_DIR}/edit/etc/os-release
	elif [[ -f ${UNPACK_DIR}/extract/casper/build.txt ]]; then
		if [[ $(${UNPACK_DIR}/extract/casper/build.txt | wc -l) -ge 1 ]]; then
			source ${UNPACK_DIR}/extract/casper/build.txt
		else
			if [[ -f ${UNPACK_DIR}/edit/etc/os-release ]]; then
				source ${UNPACK_DIR}/edit/etc/os-release
			else
				source /etc/os-release
			fi
			MUK_DIR=$(cat ${UNPACK_DIR}/extract/casper/build.txt)
		fi 
	else
		source /etc/os-release
	fi

	# Second: Figure out what to name the ISO to avoid conflicts
	_title "Determining ISO filename and patching \"grub.cfg\"...."
	ISO_FILE=${ID}-${VERSION_ID}-${MUK_BUILD:-"desktop-amd64"}
	ISO_FILE=${ISO_FILE,,}
	[[ "${FLAG_ADD_DATE}" == "1" ]] && ISO_FILE=${ISO_FILE}-$(date +"%Y%m%d")
	if [[ -f "${ISO_DIR}/${ISO_FILE}.iso" ]]; then
		ISO_FILE=${ISO_FILE}-$(( $(ls ${ISO_DIR}/${ISO_FILE}-* | sed "s|${ISO_DIR}/${ISO_FILE}-||" | sed "s|\.iso||" | sort -n | tail -1) + 1 ))
	fi

	# Third: Try to patch grub.cfg for successful LiveCD boot.  Why this is necessary is beyond me.....
	FILE=${UNPACK_DIR}/extract/boot/grub/grub.cfg
	sed -i "s|boot=casper ||g" ${FILE}
	sed -i "s|file=|boot=casper file=|g" ${FILE}

	# Fourth: Create the ISO
	_title "Building ${BLUE}${ISO_FILE}.iso${GREEN}...."
	source /etc/os-release
	test -f ${UNPACK_DIR}/extract/casper/build.txt && source ${UNPACK_DIR}/extract/casper/build.txt
	if [[ "${VERSION_ID/\./}" -lt 2204 ]]; then
		# >>>> OLD WAY TO CREATE ISO: Not valid for Jammy and above <<<<<
		# Create the ISO the old way:
		cd ${UNPACK_DIR}/extract
		test -d isolinux || cp -aR ${MUK_DIR}/files/isolinux ./
		if [[ "${FLAG_MKISOFS}" == "0" ]]; then
			genisoimage -allow-limited-size -D -r -V "${ISO_LABEL}" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ${ISO_DIR}/${ISO_FILE}.iso .
		else
			mkisofs -allow-limited-size -D -r -V "${ISO_LABEL}" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ${ISO_DIR}/${ISO_FILE}.iso .
		fi
	else
		# >>>> NEW WAY TO CREATE ISO: Valid for Jammy and above <<<<<
		if [[ ! -f ${UNPACK_DIR}/boot_hybrid.img || ! -f ${UNPACK_DIR}/boot_efi.img ]]; then
			# Extract the MBR template for --grub2-mbr:
			ISO=$(ls ${UNPACK_DIR}/ubuntu-*.iso | head -1)
			if [[ -z "${ISO}" ]]; then _error "No Ubuntu ISO found in \"${UNPACK_DIR}\"!  Aborting!"; exit 1; fi
			dd if=${ISO} bs=1 count=432 of=${UNPACK_DIR}/boot_hybrid.img

			# Extract the EFI partition image image for -append_partition:
			INFO=($(fdisk -l ${ISO} | grep "EFI"))
			if [[ "${INFO[5]} ${INFO[6]}" != "EFI System" ]]; then _error "No EFI filesystem present in ISO!  Aborting!"; exit 1; fi
			dd if=${ISO} bs=512 skip=${INFO[1]} count=${INFO[3]} of=${UNPACK_DIR}/boot_efi.img
		fi

		# Finally pack up an ISO the new way:
		xorriso -as mkisofs -r \
  			-V 'Ubuntu 22.04 LTS MODIF (EFIBIOS)' \
  			-o ${ISO_DIR}/${ISO_FILE}.iso \
  			--grub2-mbr ${UNPACK_DIR}/boot_hybrid.img \
  			-partition_offset 16 \
  			--mbr-force-bootable \
  			-append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b ${UNPACK_DIR}/boot_efi.img \
  			-appended_part_as_gpt \
  			-iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  			-c '/boot.catalog' \
  			-b '/boot/grub/i386-pc/eltorito.img' \
				-no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  			-eltorito-alt-boot \
  			-e '--interval:appended_partition_2:::' \
				-no-emul-boot \
			${UNPACK_DIR}/extract
	fi

	# Fifth: Tell user we done!
	_title "Done building ${BLUE}${ISO_DIR}/${ISO_FILE}.iso${GREEN}!"

#==============================================================================
# Did user request to rebuild the filesystem.squashfs and the ISO together?
#==============================================================================
elif [[ "$1" == "rebuild" ]]; then
	$0 pack $2 && $0 iso $2
elif [[ "$1" == "rebuild-xz" ]]; then
	$0 pack-xz $2 && $0 iso $2

#==============================================================================
# Did user request to mount chroot environment docker folder to host machine?
#==============================================================================
elif [[ "$1" == "docker_mount" ]]; then
	_title "Mounting chroot docker directory on live system:"

	# Create the necessary directories:
	[[ ! -d ${UNPACK_DIR}/edit/home/docker/.sys ]] && mkdir -p ${UNPACK_DIR}/edit/home/docker/.sys
	[[ ! -d /var/lib/docker ]] && mkdir -p /var/lib/docker

	# Stop docker, mount docker directory inside chroot environment, then start docker:
	systemctl stop docker
	mount --bind $UNPACK_DIR/edit/home/docker/.sys /var/lib/docker
	systemctl start docker

#==============================================================================
# Did user request to unmount chroot environment docker folder from host machine?
#==============================================================================
elif [[ "$1" == "docker_umount" ]]; then
	# If the docker folder doesn't exist, exit the script:
	[[ ! -d ${UNPACK_DIR}/edit/home/docker/.sys ]] && exit

	# Generate a random file to check for mounted volume:
	ID=$(cat /dev/urandom | tr -cd 'a-zA-Z0-9' | head -c 32)
	touch ${UNPACK_DIR}/edit/home/docker/.sys/${ID} >& /dev/null

	# Does our random file exist in both places?  If not, then it's not mounted:
	MOUNT=$([[ -f /var/lib/docker/${ID} ]] && echo "Y")
	[[ -f ${UNPACK_DIR}/edit/home/docker/.sys/${ID} ]] && rm ${UNPACK_DIR}/edit/home/docker/.sys/${ID}
	if [[ -z "${MOUNT}" ]]; then
		[[ ! "$2" == "-q" ]] && _error "Docker directory in chroot environment is not mounted on host system!"
		exit 2
	fi

	# Unmount the chroot environment docker directory:
	_title "Unmounting chroot docker directory from live system:"
	systemctl stop docker
	umount -q /var/lib/docker
	systemctl start docker

#==============================================================================
# Mount my Ubuntu split-partition USB stick properly:
#==============================================================================
elif [[ "$1" == "usb_mount" ]]; then
	UB=$(blkid | grep "${USB_LIVE}" | cut -d: -f 1)
	RO=$(blkid | grep "${USB_CASPER}" | cut -d: -f 1)
	if [[ -z "${UB}" ]]; then _error "No USB Live partition 1 found! (Ref: \"$USB_LIVE\")"; exit 1; fi
	if [[ -z "${RO}" ]]; then _error "No USB Casper partition 2 found! (Ref: \"$USB_CASPER\")"; exit 1; fi
	if mount | grep -q ${UNPACK_DIR}/mnt; then umount -q ${UNPACK_DIR}/mnt || exit 1; fi
	mount | grep -q ${UNPACK_DIR}/mnt && umount -lfq ${UNPACK_DIR}/mnt
	mkdir -p ${UNPACK_DIR}/usb_{base,casper} ${UNPACK_DIR}/mnt
	if mount | grep -q ${UB}; then umount -q ${UB} || exit 1; fi
	mount ${UB} ${UNPACK_DIR}/usb_base -t vfat -o noatime,rw,nosuid,nodev,relatime,uid=1000,gid=1000,fmask=0111,dmask=0022 || exit 1
	if mount | grep -q ${RO}; then umount -q ${RO} || exit 1; fi
	mount ${RO} ${UNPACK_DIR}/usb_casper -t ext3 -o defaults,noatime || exit 1
	mount | grep -q ${UNPACK_DIR}/mnt || unionfs ${UNPACK_DIR}/usb_casper=RW:${UNPACK_DIR}/usb_base=RW ${UNPACK_DIR}/mnt -o default_permissions,allow_other,use_ino,nonempty,suid || exit 1
	_title "Finished mounting split-partition USB stick!"

#==============================================================================
# Unmount my Ubuntu split-partition USB stick properly:
#==============================================================================
elif [[ "$1" == "usb_unmount" ]]; then
	umount -q ${UNPACK_DIR}/mnt || exit 1
	umount -q ${UNPACK_DIR}/usb_base || exit 1
	umount -q ${UNPACK_DIR}/usb_casper || exit 1
	rmdir ${UNPACK_DIR}/usb_{base,casper}
	_title "Split-partition USB stick successfully unmounted!"

#==============================================================================
# Copy "extract" folder <<TO>> my Ubuntu split-partition USB stick:
#==============================================================================
elif [[ "$1" == "usb_load" ]]; then
	DEV=$(mount | grep "${UNPACK_DIR}/usb_casper" | cut -d" " -f 1)
	if [[ -z "${DEV}" ]]; then $0 usb_mount || exit 1; fi
	copy -R --verbose --update ${UNPACK_DIR}/extract/casper* ${UNPACK_DIR}/mnt/casper/
	eval `blkid -o export ${DEV}`
	FILE=${UNPACK_DIR}/mnt/boot/grub/grub.cfg
	sed -i "s| boot=casper||" ${FILE}
	sed -i "s| live-media=/dev/disk/by-uuid/[0-9a-z\-]*||" ${FILE}
	sed -i "s|vmlinuz |vmlinuz boot=casper live-media=/dev/disk/by-uuid/${UUID} |" ${FILE}
	_title "File copy to split-partition USB stick completed!"

#==============================================================================
# Copy <<FROM>> my Ubuntu split-partition USB stick to "extract" folder:
#==============================================================================
elif [[ "$1" == "usb_copy" ]]; then
	DEV=$(mount | grep "${UNPACK_DIR}/usb_casper" | cut -d" " -f 1)
	if [[ -z "${DEV}" ]]; then $0 usb_mount || exit 1; fi
	copy -R --verbose --update ${UNPACK_DIR}/mnt/casper* ${UNPACK_DIR}/extract/casper
	FILE=${UNPACK_DIR}/extract/boot/grub/grub.cfg
	sed -i "s| live-media=/dev/disk/by-uuid/[0-9a-z\-]*||g" ${FILE}
	_title "File copy from split-partition USB stick completed!"

#==============================================================================
# Update snap configuration (REQUIRES LIVE CD!)
#==============================================================================
elif [[ "$1" == "snap_rebuild" || "$1" == "snap_rebuild_test" ]]; then
	# If we are NOT in a Live CD environment, abort with error!
	if ! mount | grep -q " / " | grep "/cow "; then _error "Live CD not detected!  Aborting"; exit 1; fi

	if [[ "$1" == "snap_rebuild" ]]; then
		_title "Disabling current snaps...."
		SNAPS=($(snap list --all 2> /dev/null | awk '{print $1}' | sed "/^Name$/d"))
		for SNAP in ${SNAPS[@]}; do snap disable ${SNAP}; done

		_title "Unmounting snap-related directories..."
		mount | grep "/var/snap" | awk '{print $3}' | while read DIR; do umount ${DIR}; done

		_title "Removing current snaps..."
		while [[ "${#SNAPS[@]}" -gt 0 ]]; do
			snap list --all 2> /dev/null | grep -ve "^Name" | awk '{print $1}' | while read SNAP; do snap remove ${SNAP}; done
			SNAPS=($(snap list --all 2> /dev/null | awk '{print $1}' | sed "/^Name$/d"))
		done

		_title "Purging \"snapd\" package and settings..."
		apt purge -y snapd
		rm -rf /var/{snap,lib/snap,lib/snapd} /etc/systemd/system/snap*

		_title "Reinstalling \"snapd\" package..."
		apt install -y snapd
	else
		SNAPS=(bare core22 gnome-42-2204 gtk-common-themes snap-store snapd snapd-desktop-integration)
	fi

	_title "Downloading current versions of available snaps..."
	mkdir -p /var/lib/snapd/seed/{assertions,snaps}
	cd /tmp
	YAML=/var/lib/snapd/seed/seed.yaml
	echo "snaps:" > ${YAML}
	SNAP_DIR=/var/lib/snapd/snaps/
	SEEDS=/var/lib/snapd/seed/snaps
	ASSERT=/var/lib/snapd/seed/assertions/
	for SNAP in snapd core22 ${SNAPS[@]}; do
		if [[ ! -f ${SNAP_DIR}/${SEED}_*.snap ]]; then
			snap download ${SNAP}
			snap ack ${SNAP}_*.assert
			mv ${SNAP}_*.assert ${ASSERT}/
			FILE=$(basename ${SNAP}_*.snap)
			snap install ${FILE}
			test -f ${SEEDS}/${FILE} || ln ${SNAP_DIR}/${FILE} ${SEEDS}/${FILE}
		fi
		FILE=$(basename ${SNAP}_*.snap)
		grep -q "${FILE}" ${YAML} || (echo -e "\t-"; echo -e "\t\tname: ${SNAP}"; echo -e "\t\tchannel: stable"; echo -e "\t\tfile: ${FILE}") >> ${YAML}
	done
	_title "Completed rebuilding the snap configuration!"

#==============================================================================
# Copy snap configuration from persistent partition:
#==============================================================================
elif [[ "$1" == "snap_copy" ]]; then
	# If we are in a Live CD environment, abort with error!
	if ! blkid | grep -q "LABEL=\"casper-rw\""; then _error "No persistent partition labeled \"casper-rw\" found!  Aborting!"; exit 1; fi

	# Mount persistent partiton and chroot environment:
	_title "Mounting partition with label \"casper-rw\"..."
	mkdir -p ${UNPACK_DIR}/.casper
	if mount | grep -q ${UNPACK_DIR}/.casper; then umount -q ${UNPACK_DIR}/.casper || exit 1; fi
	mount LABEL=casper-rw ${UNPACK_DIR}/.casper || exit 1
	$0 mount || exit 1

	# Replace existing snap directories with those from the casper-rw partition:
	_title "Replacing snap directories..."
	SRC=${UNPACK_DIR}/.casper/upper
	EDIT=${UNPACK_DIR}/edit
	rm -rf ${EDIT}/var/lib/snapd
	cp -aR ${SRC}/var/lib/snapd ${EDIT}/var/lib/
	rm -rf ${EDIT}/var/snap
	cp -aR ${SRC}/var/snap ${EDIT}/var/
	rm -rf ${EDIT}/snap
	cp -aR ${SRC}/snap ${EDIT}/
	rm -rf ${EDIT}/etc/systemd/system/snap*
	cp -aR ${SRC}/etc/systemd/system/snap* ${EDIT}/etc/systemd/system/ 2> /dev/null
	_title "Completed copying the snap configuration!"

#==============================================================================
# Invalid parameter specified.  List available parameters:
#==============================================================================
else
	[[ ! "$1" == "--help" ]] && echo "Invalid parameter specified!"
	echo "Usage: edit_chroot [OPTION]"
	echo ""
	echo "Available commands:"
	echo -e "  ${GREEN}unpack${NC}         Copies the Ubuntu installer files from DVD or ISO on hard drive."
	echo -e "  ${GREEN}pack${NC}           Packs the unpacked filesystem into ${BLUE}filesystem.squashfs${NC}."
	echo -e "  ${GREEN}pack-xz${NC}        Packs the unpacked filesystem using XZ compression into ${BLUE}filesystem.squashfs${NC}."
	echo -e "  ${GREEN}changes${NC}        Packs changes to ${BLUE}filesystem.squashfs${NC} into it's own squashfs file."
	echo -e "  ${GREEN}changes-xz${NC}     Packs changes to ${BLUE}filesystem.squashfs${NC} using XZ compression into it\'s own squashfs file."
	echo -e "  ${GREEN}iso${NC}            Builds an ISO image in ${BLUE}${ISO_DIR}${NC} containing the packed filesystem."
	echo -e "  ${GREEN}rebuild${NC}        Combines ${GREEN}--pack${NC} and ${GREEN}--iso${NC} options."
	echo -e "  ${GREEN}rebuild-xz${NC}     Combines ${GREEN}--pack-xz${NC} and ${GREEN}--iso${NC} options."
	echo -e "  ${GREEN}build${NC}          Enter the unpacked filesystem environment to install specified series of packages."
	echo -e "  ${GREEN}enter${NC}          Enter the unpacked filesystem environment to make changes."
	echo -e "  ${GREEN}upgrade${NC}        Only upgrades Ubuntu packages with updates available."
	echo -e "  ${GREEN}unmount${NC}        Safely unmounts all unpacked filesystem mount points."
	echo -e "  ${GREEN}remove${NC}         Safely removes the unpacked filesystem from the hard drive."
	echo -e "  ${GREEN}update${NC}         Updates this script with the latest version."
	echo -e "  ${GREEN}--help${NC}         This message"
	echo -e ""
	echo "Docker-related commands:"
	echo -e "  ${GREEN}docker_mount${NC}   Mounts the chroot docker directory to host docker directory."
	echo -e "  ${GREEN}docker_umount${NC}  Unmounts the chroot docker directory to host docker directory."
	echo -e ""
	echo "Custom split-partition USB drive related commands:"
	echo -e "  ${GREEN}usb_mount${NC}      Mount my custom split-partition USB drive."
	echo -e "  ${GREEN}usb_unmount${NC}    Properly unmount my custom split-partition USB drive."
	echo -e "  ${GREEN}usb_load${NC}       Copy hard drive edition to my custom split-partition USB drive."
	echo -e "  ${GREEN}usb_copy${NC}       Copy custom split-partition USB drive to hard drive edition."
	echo -e ""
	echo "Snap-related commands:"
	echo -e "  ${GREEN}snap_rebuild${NC}   Rebuilds snap directories with latest versions of each snap.  ${RED}LIVE CD REQUIRED!${NC}"
	echo -e "  ${GREEN}snap_copy${NC}      Copy snap configuration from persistent partition."
	echo -e ""
	echo -e "Note that this command ${RED}REQUIRES${NC} root access in order to function it's job!"
fi
[[ "$1" =~ (usb_|docker_|)(un|)mount ]] || echo -e ""
