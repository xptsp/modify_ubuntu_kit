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
# Flag: Set to 1 to use RAM for temp folder.  Defaults to 0.
export FLAG_TMP_RAM=${FLAG_TMP_RAM:-"0"}
# Where to place extracted and chroot environment directories.  Defaults to "/img".
export UNPACK_DIR=${UNPACK_DIR:-"/img"}
# Where to place the generated ISO file.  Defaults to current directory.
export ISO_DIR=${ISO_DIR:-"${UNPACK_DIR}"}
# ISO name prefix string.  Defaults to "ubuntu".  (format: prefix-version-postfix)
export ISO_PREFIX=${ISO_PREFIX:-"Ubuntu"}
# ISO postfix string.  Defaults to "desktop".  (format: prefix-version-postfix)
export ISO_POSTFIX=${ISO_POSTFIX:-"desktop"}
# Label to use for ISO.  Defaults to "${ISO_PREFIX} ${ISO_VERSION}"
ISO_LABEL=$([[ -z "${ISO_LABEL}" ]] && echo ${ISO_PREFIX} ${ISO_VERSION} || echo ${ISO_LABEL})
# Default sto removing old kernels from chroot environment.  Set to 0 to prevent this.
OLD_KERNEL=${OLD_KERNEL:-"1"}
# Determine ISO version number to use:
[[ -f ${UNPACK_DIR}/edit/etc/os-release ]] && ISO_VERSION=$(cat ${UNPACK_DIR}/edit/etc/os-release | grep "PRETTY" | cut -d "\"" -f 2 | cut -d " " -f 2)
# MUK path:
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}

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
	if [[ -z $MKSQUASH || -z $GENISO || -z $GIT ]]; then
		_title "Installing necessary packages"
		apt-get update >& /dev/null
		apt-get install -y $([[ -z $MKSQUASH ]] && echo "squashfs-tools") $([[ -z $GENISO ]] && echo "genisoimage") $([[ -z $GIT ]] && echo "git")
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
elif [[ "$1" == "enter" || "$1" == "upgrade" || "$1" == "build" ]]; then
	#==========================================================================
	# Determine if we are working inside or outside the CHROOT environment
	#==========================================================================
	if [[ $(ischroot; echo $?) -eq 1 ]]; then
		#======================================================================
		# RESULT: We are outside the chroot environment:
		#======================================================================
		### First: Make sure that the CHROOT environment actually exists:
		if [[ ! -d ${UNPACK_DIR}/edit/etc ]]; then
			_error "No unpacked filesystem!  Use ${BLUE}edit_chroot unpack${GREEN} first!"
			exit 1
		elif [[ "$1" == "build" ]]; then
			if [[ ! "$2" == "base" && ! "$2" == "desktop" && ! "$2" == "htpc" && ! "$2" == "docker" ]]; then
				_error "Invalid parameter!  Supported values are: ${RED}base${GREEN}, ${RED}desktop${GREEN}, ${RED}htpc${GREEN} and ${RED}docker${GREEN}!"
				exit 1
			fi
		fi

		### Second: Update MUK, then setup the CHROOT environment:
		$0 update
		cd ${UNPACK_DIR}
		$0 unmount
		cp /etc/resolv.conf ${UNPACK_DIR}/edit/etc/
		cp /etc/hosts ${UNPACK_DIR}/edit/etc/
		mount --bind /run/ ${UNPACK_DIR}/edit/run
		mount --bind /dev/ ${UNPACK_DIR}/edit/dev
		if [[ -e /var/run/docker.sock ]]; then
			touch ${UNPACK_DIR}/edit/var/run/docker.sock
			mount --bind /var/run/docker.sock ${UNPACK_DIR}/edit/var/run/docker.sock
		fi

		### Third: Copy MUK into chroot environment:
		rm -rf ${UNPACK_DIR}/edit${MUK_DIR}
		cp -aR ${MUK_DIR} ${UNPACK_DIR}/edit/opt/

		### Fourth: Enter the CHROOT environment:
		_title "Entering CHROOT environment"
		chroot ${UNPACK_DIR}/edit ${MUK_DIR}/edit_chroot.sh $@
		[[ -f ${UNPACK_DIR}/edit/usr/local/finisher/build.txt ]] && cp ${UNPACK_DIR}/edit/usr/local/finisher/build.txt ${UNPACK_DIR}/extract/casper/build.txt

		### Fifth: Run required commands outside chroot commands:
		if [[ -f ${UNPACK_DIR}/edit/usr/local/finisher/outside_chroot.list ]]; then
			_title "Executing scripts outside of CHROOT environment..."
			(while read p; do ${UNPACK_DIR}/edit/$p; done) < ${UNPACK_DIR}/edit/usr/local/finisher/outside_chroot.list >& /dev/null
		fi

		### Sixth: Remove mounts for CHROOT environment:
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
		[[ "${FLAG_TMP_RAM}" == "1" ]] && mount -t tmpfs tmpfs /tmp
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

		### Second: Install the chroot tools if required:
		${MUK_DIR}/install.sh

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
			echo $2 > /usr/local/finisher/build.txt
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
		_title "Removing unnecessary packages and fixing any broken packages..."
		apt-get install -f --autoremove --purge -y
		_title "Upgrading any packages requiring upgrading..."
		apt-get dist-upgrade -y

		### Ninth: Remove any unnecessary packages:
		CURRENT=$(ls -l /initrd.img* | cut -d">" -f 2 | cut -d"-" -f2,3 | sort -r | head -1)
		KERNELS=$(dpkg -l | grep linux-image | grep "ii" | awk '{print$2}' | grep -v "$CURRENT" | grep -v "hwe" | perl -pe '($_)=/([0-9]+([.-][0-9]+)+)/' )
		if [[ "${OLD_KERNEL:-"0"}" == "1" && ! -z "${KERNELS}" ]]; then
			_title "Removing old kernels packages and unnecessary packages..."
			apt-get remove --autoremove --purge -y ${KERNELS}*
		fi
		_title "Cleaning up cached packages..."
		apt-get autoclean -y >& /dev/null
		apt-get clean -y >& /dev/null

		### Tenth: Disable services not required during Live ISO:
		if [[ -f /usr/local/finisher/disabled.list ]]; then
			_title "Disabling unnecessary services for Live CD..."
			(while read p r; do systemctl disable $p; done) < /usr/local/finisher/disabled.list >& /dev/null
		fi

		### Eleventh: Clean up everything done to "chroot" into this ISO image:
		_title "Undoing CHROOT environment modifications..."
		chmod 440 /etc/sudoers.d/*
		rm -rf /tmp/* ~/.bash_history
		rm /var/lib/dbus/machine-id
		rm /sbin/initctl
		dpkg-divert --rename --remove /sbin/initctl >& /dev/null
		[[ "${FLAG_TMP_RAM}" == "1" ]] && umount /tmp
		umount /proc || umount -lf /proc
		umount /sys
		umount /dev/pts
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
	umount ${UNPACK_DIR}/edit/tmp >& /dev/null
	(umount ${UNPACK_DIR}/edit/proc || umount -lf ${UNPACK_DIR}/edit/proc) >& /dev/null
	umount ${UNPACK_DIR}/edit/sys >& /dev/null
	umount ${UNPACK_DIR}/edit/dev/pts >& /dev/null
	umount ${UNPACK_DIR}/edit/dev >& /dev/null
	umount ${UNPACK_DIR}/edit/run >& /dev/null
	if [[ -e ${UNPACK_DIR}/edit/var/run/docker.sock ]]; then
		umount ${UNPACK_DIR}/edit/var/run/docker.sock >& /dev/null
		rm ${UNPACK_DIR}/edit/var/run/docker.sock
	fi
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
	_title "Removing folder ${BLUE}${UNPACK_DIR}/edit${GREEN} safely..."
	EDIT_FS=$(cat /etc/fstab | grep -e "^tmpfs" | grep " /img/edit ")
	if [[ ! -z "${EDIT_FS}" ]]; then
		umount ${UNPACK_DIR}/edit
		mount ${UNPACK_DIR}/edit
	else
		rm -rf ${UNPACK_DIR}/edit
	fi
	_title "Unpacked filesystem has been removed."

#==============================================================================
# Did user request to unpack the ISO?
#==============================================================================
elif [[ "$1" == "unpack" ||  "$1" == "unpack-iso" || "$1" == "unpack-full" || "$1" == "unpack-distro" ]]; then
	# First: Make sure everything is okay before proceeding:
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_error "Cannot use ${BLUE}unpack${GREEN} inside chroot environment!"
		exit 1
	fi
	[ ! -d ${UNPACK_DIR}/mnt ] && mkdir -p ${UNPACK_DIR}/mnt
	umount ${UNPACK_DIR}/mnt >& /dev/null
	if [[ "$1" == "unpack" ]]; then
		MNT=$((mount /dev/cdrom ${UNPACK_DIR}/mnt >& /dev/null) && echo "mnt" || echo "extract")
		[ "${MNT}" == "extract" ] && _error "No DVD in the drive!  Trying ${BLUE}extract${GREEN} folder..."
	elif [[ "$1" == "unpack-distro" ]]; then
		if [[ ! -f ${UNPACK_DIR}/$2/casper/filesystem.squashfs ]]; then
			_error "Cannot find a ${BLUE}filesystem.squashfs${GREEN} to extract!!!"
			exit 1
		fi
		MNT="$2"
	elif [[ -z "$2" ]]; then
		MNT=extract
		_error "No ISO specified!  Trying ${BLUE}extract${GREEN} folder..."
	else
		ISO=$2
		[[ -f "${ISO}" && "$(basename ${ISO})" == "$ISO" ]] && ISO=$(pwd)/$ISO
		MNT=$((mount -o loop $ISO ${UNPACK_DIR}/mnt >& /dev/null) && echo "mnt" || echo "extract")
		[ "${MNT}" == "extract" ] && _error "Specified ISO unable to be mounted!  Trying ${BLUE}extract${GREEN} folder..."
	fi
	cd ${UNPACK_DIR}
	if [[ ! -f ${MNT}/casper/filesystem.squashfs ]]; then
		_error "Cannot find a ${BLUE}filesystem.squashfs${GREEN} to extract!!!"
		exit 1
	fi

	# Second: Copy the necessary files to the hard drive:
	_title "Found ${BLUE}filesystem.squashfs${GREEN} in ${BLUE}${UNPACK_DIR}/${MNT}${GREEN}!!!"
	if [[ ! "$1" == "unpack-distro" && "$MNT" == "mnt" ]] ; then
		_title "Copying everything$([[ "$1" == "unpack-full" ]] || echo " but ${BLUE}filesystem.squashfs${GREEN}")..."
		[ ! -d extract ] && mkdir extract
		rsync $([[ "$1" == "unpack-full" ]] || echo "--exclude=/casper/filesystem.squashfs") -a mnt/ extract
	fi
	if [[ -d edit ]]; then
		_title "Removing folder ${BLUE}edit${GREEN} for clean extraction..."
		$0 remove
	fi

	# Third: Unpack the main squashfs file:
	_title "Unpacking ${BLUE}filesystem.squashfs${GREEN} to ${BLUE}edit${GREEN}..."
	unsquashfs -f -d edit ${MNT}/casper/filesystem.squashfs

	# Fourth: Unpack the split squashfs file into the main unpacked filesystem:
	if [[ -f ${MNT}/casper/filesystem-opt.squashfs && -f ${MNT}/casper/filesystem-opt.location ]]; then
		_title "Unpacking ${BLUE}filesystem-opt.squashfs${GREEN} to ${BLUE}${LOC}${GREEN}..."
		IN2=edit/tmp/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
		DST=$(cat ${MNT}/casper/filesystem-opt.location)
		unsquashfs -f -d ${IN2} ${MNT}/casper/filesystem-opt.squashfs
		mv ${IN2}/${DST}/* edit/${DST}/
		rm -rf ${IN2}
	fi
		
	# Fifth: Unmount the DVD/ISO if necessary:
	if [[ "${MNT}" == "mnt" || ("$1" != "unpack" && ! "$1" == "unpack-distro") ]]; then
		_title "Unmounting DVD/ISO from mount point...."
		umount mnt
	fi

	# Sixth: Tell user we done!
	_title "Ubuntu ISO unpacked!"

#==============================================================================
# Did user request to pack the chroot environment?
#==============================================================================
elif [[ "$1" == "pack" || "$1" == "pack-xz" ]]; then
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
	[ -f ${UNPACK_DIR}/edit/etc/debian_chroot ] && rm ${UNPACK_DIR}/edit/etc/debian_chroot
	rm -rf ${UNPACK_DIR}/edit${MUK_DIR}
	cp -R ${MUK_DIR} ${UNPACK_DIR}/edit/opt/

	# Second: Copy the new INITRD from the unpacked filesystem:
	cd ${UNPACK_DIR}/edit
	INITRD=$(ls initrd.img-* 2> /dev/null | sort -r | head -1)
	[[ -z "${INITRD}" ]] && INITRD_SRC=$(ls boot/initrd.img-* 2> /dev/null | sort -r | head -1)
	if [[ -z "${INITRD_SRC}" ]]; then
		_error "No VMLINUZ file detected in chroot environment!  Skipping!"
	else
		_title "Copying INITRD from unpacked filesystem from ${BLUE}${INITRD_SRC}${GREEN}..."
		cp -p ${UNPACK_DIR}/edit/${INITRD_SRC} ${UNPACK_DIR}/extract/casper/initrd
	fi

	# Third: Copy the new VMLINUZ from the unpacked filesystem:	
	VMLINUZ=$(ls vmlinuz-* 2> /dev/null | sort -r | head -1)
	[[ -z "${VMLINUZ}" ]] && VMLINUZ=$(ls boot/vmlinuz-* 2> /dev/null | sort -r | head -1)
	if [[ -z "${VMLINUZ}" ]]; then
		_error "No VMLINUZ file detected in chroot environment!  Skipping!"
	else
		_title "Copying VMLINUZ from unpacked filesystem from ${BLUE}${VMLINUZ}${GREEN}...."
		cp -p ${UNPACK_DIR}/edit/${VMLINUZ} ${UNPACK_DIR}/extract/casper/vmlinuz
	fi

	# Fourth: Build the list of installed packages in unpacked filesystem:
	cd ${UNPACK_DIR}
	_title "Building list of installed packages...."
	chmod +w extract/casper/filesystem.manifest >& /dev/null
	chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' | tee extract/casper/filesystem.manifest >& /dev/null
	cp extract/casper/filesystem.manifest extract/casper/filesystem.manifest-desktop
	sed -i '/ubiquity/d' extract/casper/filesystem.manifest-desktop
	sed -i '/casper/d' extract/casper/filesystem.manifest-desktop

	# Fifth: Sset necessary flags for compression:
	[[ ! "$(echo $@ | grep pack-xz)" == "" ]] && FLAG_XZ=1
	XZ=$([[ ${FLAG_XZ:-"0"} == "1" ]] && echo "-comp xz -Xdict-size 100%")

	# Sixth: Pack the filesystem-opt.squashfs if required:
	[[ "$(echo $@ | grep skip-opt)" == "" && -f extract/casper/filesystem-opt.squashfs ]] && rm extract/casper/filesystem-opt.*
	if [[ "$(echo $@ | grep skip-opt)" == "" && ! -z "${SPLIT_OPT}" && -d edit/opt/${SPLIT_OPT} ]]; then
		_title "Building ${BLUE}filesystem-opt.squashfs${GREEN}...."
		(ls edit | grep -v "^opt$"; for file in $(ls edit/opt | grep -v "^${SPLIT_OPT}$"); do echo opt/${file}; done) > /tmp/exclude
		FILE=.$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
		touch edit/${FILE}
		mksquashfs edit extract/casper/filesystem-opt.squashfs -b 1048576 -ef /tmp/exclude ${XZ}
		rm edit/${FILE}
		echo opt/${SPLIT_OPT} > extract/casper/filesystem-opt.location
	fi

	# Seventh: Pack the filesystem-opt.squashfs if required:
	_title "Building ${BLUE}filesystem.squashfs${GREEN}...."
	if [[ ! -z "${SPLIT_OPT}" && -d edit/opt/${SPLIT_OPT} ]]; then
		echo opt/${SPLIT_OPT}/* > /tmp/exclude
		XZ="${XZ} -ef /tmp/exclude -wildcards"
	fi
	[[ -f extract/casper/filesystem.squashfs ]] && rm extract/casper/filesystem.squashfs
	mksquashfs edit extract/casper/filesystem.squashfs -b 1048576 ${XZ}
	[[ -f /tmp/exclude ]] && rm /tmp/exclude

	# Eighth: If "KEEP_CIFS" flag is set, remove the "cifs-utils" package from the list of stuff to
	[[ "${KEEP_CIFS:-"0"}" == "1" && -f extract/casper/filesystem.manifest-remove ]] && sed -i '/cifs-utils/d' extract/casper/filesystem.manifest-remove

	# Ninth: Create the "filesystem.size" and "md5sum.list" files:
	_title "Building ${BLUE}filesystem.size${GREEN} and ${BLUE}md5sum.list${GREEN}...."
	printf $(du -sx --block-size=1 edit | cut -f1) | tee extract/casper/filesystem.size >& /dev/null
	cd extract
	[ -f md5sum.list ] && rm md5sum.list
	find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.list >& /dev/null

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
	elif [[ ! -d "${ISO_DIR}" ]]; then
		_error "Changing ISO destination to ${BLUE}$(pwd)${GREEN}...."
		ISO_DIR=$(pwd)
	fi

	# First: Figure out what to name the ISO to avoid conflicts
	_title "Determining ISO filename...."
	[[ "$(dirname ${ISO_DIR})" == "." ]] && ISO_DIR=$(pwd)
	if [[ -f ${UNPACK_DIR}/extract/casper/build.txt ]]; then
		ISO_POSTFIX=$(cat ${UNPACK_DIR}/extract/casper/build.txt)
	elif [[ -e ${UNPACK_DIR}/edit/usr/local/finisher/build.txt ]]; then
		ISO_POSTFIX=$(cat ${UNPACK_DIR}/edit/usr/local/finisher/build.txt)
	else
		ISO_POSTFIX=amd64
	fi
	ISO_FILE=${ISO_PREFIX}-${ISO_VERSION}-${ISO_POSTFIX}
	[[ "${FLAG_ADD_DATE}" == "1" ]] && ISO_FILE=${ISO_FILE}-$(date +"%Y%m%d")
	if [[ -f "${ISO_DIR}/${ISO_FILE}.iso" ]]; then
		COUNTER=1
		while [ -f "${ISO_DIR}/${ISO_FILE}-${COUNTER}.iso" ]; do COUNTER=$((COUNTER+1)); done
		ISO_FILE=${ISO_FILE}-${COUNTER}
	fi

	# Second: Create the ISO
	_title "Building ${BLUE}${ISO_FILE}.iso${GREEN}...."
	cd ${UNPACK_DIR}/extract
	if [[ "${FLAG_MKISOFS}" == "0" ]]; then
		mkisofs -D -r -V "${ISO_LABEL}" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ${ISO_DIR}/${ISO_FILE}.iso .
	else
		genisoimage -allow-limited-size -D -r -V "${ISO_LABEL}" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ${ISO_DIR}/${ISO_FILE}.iso .
	fi

	# Third: Tell user we done!
	_title "Done building ${BLUE}${ISO_DIR}/${ISO_FILE}.iso${GREEN}!"

#==============================================================================
# Did user request to rebuild the filesystem.squashfs and the ISO together?
#==============================================================================
elif [[ "$1" == "rebuild" ]]; then
	$0 pack $2 && $0 iso $2
	exit 0
elif [[ "$1" == "rebuild-xz" ]]; then
	$0 pack-xz $2 && $0 iso $2
	exit 0

#==============================================================================
# Did user ask to rebuild part of or all of RedDragon distros?
#==============================================================================
elif [[ "$1" == "rdbuild" ]]; then
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
		$0 unpack-full ${USB}/_ISO/MAINMENU/1*.iso
		mv ${EXT} ${ORG}
		ln -sf ${ORG} ${EXT}

		# Unmount the factory Xubuntu 18.04 ISO:
		umount ${USB}
	else
		[[ -d ${EXT} ]] && rm -rf ${EXT} || rm ${EXT}
		UPK=${ORG}
		[[ "$2" == "desktop" ]] && UPK=${PTN2}
		[[ "$2" == "htpc" ]] && UPK=${PTN3}
		ln -sf ${UPK} ${EXT}
		$0 unpack
	fi

	# Create our "base" install:
	if [[ -z "$2" || "$2" == "base" ]]; then
		[[ -f ${PTN2} ]] && rm -rf ${PTN2}
		cp -R ${ORG} ${PTN2}
		rm ${EXT}
		ln -sf ${PTN2} ${EXT}
		$0 build base
		$0 rebuild
	fi

	# Create our "desktop" install:
	if [[ -z "$2" || "$2" == "desktop" ]]; then
		[[ -f ${PTN3} ]] && rm -rf ${PTN3}
		cp -R ${ORG} ${PTN3}
		rm ${EXT}
		ln -sf ${PTN3} ${EXT}
		$0 build desktop
		$0 rebuild
	fi

	# Create our "htpc" install:
	if [[ -z "$2" || "$2" == "htpc" ]]; then
		[[ -f ${PTN4} ]] && rm -rf ${PTN4}
		cp -R ${ORG} ${PTN4}
		rm ${EXT}
		ln -sf ${PTN4} ${EXT}
		$0 build htpc
		$0 rebuild
	fi

#==============================================================================
# Did user request to copy RedDragon distros to USB stick?
#==============================================================================
elif [[ "$1" == "rdcopy" ]]; then
	# Abort if the RedDragon USB stick isn't found:
	${MUK_DIR}/files/RD_Restore.sh || exit 1
	DEV=$(blkid | grep "RedDragon USB" | cut -d":" -f 1)

	# Mount the RedDragon USB stick:
	_title "Mounting the RedDragon USB Stick...."
	while [[ ! -z "$(mount | grep "${DEV}")" ]]; do umount ${DEV}; sleep 1; done
	[[ ! -d ${USB} ]] && mkdir -p ${USB}
	mount ${DEV} ${USB}

	if [[ -z "$2" || "$2" == "base" ]]; then
		_title "Copying the Base edition to the USB stick..."
		mount ${USB}/_ISO/MAINMENU/2* ${MNT}
		cp ${PTN2}/casper/* ${MNT}/casper/
		_title "Unmounting Base edition image partition..."
		umount ${MNT}
	fi

	if [[ -z "$2" || "$2" == "desktop" ]]; then
		_title "Copying the Desktop edition to the USB stick..."
		mount ${USB}/_ISO/MAINMENU/3* ${MNT}
		cp ${PTN3}/casper/* ${MNT}/casper/
		_title "Unmounting Desktop edition image partition..."
		umount ${MNT}
	fi

	if [[ -z "$2" || "$2" == "htpc" ]]; then
		_title "Copying the HTPC edition to the USB stick..."
		mount ${USB}/_ISO/MAINMENU/4* ${MNT}
		cp ${PTN4}/casper/* ${MNT}/casper/
		_title "Unmounting HTPC  edition image partition..."
		umount ${MNT}
	fi

	_title "Unmounting RedDragon USB stick..."
	umount ${USB}
	if [[ ! "$(echo $@ | grep "noeject")" == "" ]]; then
		_title "Ejecting RedDragon USB stick..."
		eject ${DEV}
	fi
	_title "Done!"

#==============================================================================
# Invalid parameter specified.  List available parameters:
#==============================================================================
else
	[[ ! "$1" == "--help" ]] && echo "Invalid parameter specified!"
	echo "Usage: edit_chroot [OPTION]"
	echo ""
	echo "Available commands:"
	echo -e "  ${GREEN}unpack${NC}      Unpacks the Ubuntu filesystem from DVD or extracted ISO on hard drive."
	echo -e "  ${GREEN}unpack-iso${NC}  Unpacks the Ubuntu filesystem from ISO on hard drive."
	echo -e "  ${GREEN}unpack-full${NC} Unpacks the Ubuntu filesystem from ISO on hard drive, including ${GREEN}filesystem.squashfs{$NC}!"
	echo -e "  ${GREEN}pack${NC}        Packs the unpacked filesystem into ${BLUE}filesystem.squashfs${NC}."
	echo -e "  ${GREEN}pack-xz${NC}     Packs the unpacked filesystem using XZ compression into ${BLUE}filesystem.squashfs${NC}."
	echo -e "  ${GREEN}iso${NC}         Builds an ISO image in ${BLUE}${ISO_DIR}${NC} containing the packed filesystem."
	echo -e "  ${GREEN}rebuild${NC}     Combines ${GREEN}--pack${NC} and ${GREEN}--iso${NC} options."
	echo -e "  ${GREEN}rebuild-xz${NC}  Combines ${GREEN}--pack-xz${NC} and ${GREEN}--iso${NC} options."
	echo -e "  ${GREEN}build${NC}       Enter the unpacked filesystem environment to install specified series of packages."
	echo -e "  ${GREEN}enter${NC}       Enter the unpacked filesystem environment to make changes."
	echo -e "  ${GREEN}upgrade${NC}     Only upgrades Ubuntu packages with updates available."
	echo -e "  ${GREEN}unmount${NC}     Safely unmounts all unpacked filesystem mount points."
	echo -e "  ${GREEN}remove${NC}      Safely removes the unpacked filesystem from the hard drive."
	echo -e "  ${GREEN}update${NC}      Updates this script with the latest version."
	echo -e "  ${GREEN}--help${NC}      This message"
	echo -e ""
	echo "Red Dragon Distro-related commands:"
	echo -e "  ${GREEN}rdbuild${NC}     Builds one or all Red Dragon distro builds."
	echo -e "  ${GREEN}rdcopy${NC}      Copies Red Dragon distros to the Red Dragon USB stick."
	echo -e ""
	echo -e "Note that this command ${RED}REQUIRES${NC} root access in order to function it's job!"
fi
echo -e ""
