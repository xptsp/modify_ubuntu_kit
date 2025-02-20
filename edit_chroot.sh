#!/bin/bash

#==============================================================================
# Script settings and their defaults:
#==============================================================================
# If exists, load the user settings into the script:
[[ -f /usr/local/finisher/settings.conf ]] && source /usr/local/finisher/settings.conf
[[ -f /etc/default/edit_chroot ]] && source /etc/default/edit_chroot
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
export USB_LIVE=${USB_LIVE:-"LABEL=\"UBUNTU_EFI\""}
export USB_LIVE=$(echo ${USB_LIVE} | cut -d= -f 1)=\"$(echo ${USB_LIVE} | cut -d= -f 2 | sed "s|\"||g")\"
# Custom USB Stick partition #2 identification:
export USB_CASPER=${USB_CASPER:-"LABEL=\"UBUNTU_CASPER\""}
echo ${USB_CASPER} | grep -q "=" && export USB_CASPER=$(echo ${USB_CASPER} | cut -d= -f 1)=\"$(echo ${USB_CASPER} | cut -d= -f 2 | sed "s|\"||g")\"

#==============================================================================
# Get the necessary functions in order to function correctly:
#==============================================================================
export INC_SRC=${MUK_DIR}/files/includes.sh
test -e ${INC_SRC} || export INC_SRC=/usr/share/edit_chroot/includes.sh
if [[ ! -e ${INC_SRC} ]]; then echo Missing includes file!  Aborting!; exit 1; fi
source ${INC_SRC}
[[ $(ischroot; echo $?) -ne 1 ]] || systemctl daemon-reload

export UI=$([[ "$1" =~ -ui$ ]] && echo "Y" || echo "N")
export ACTION=${1/-ui/}
function _ui_title() { if [[ "$UI" == "N" ]]; then _title $@; else dialog --msgbox "$@" 8 60; clear; fi }
function _ui_error() { if [[ "$UI" == "N" ]]; then _error $@; else dialog --msgbox "$@" 8 60; clear; fi }

#==============================================================================
# If no help is requested, make sure script is running as root and needed
# packages have been installed on this computer.
#==============================================================================
if [[ ! "${ACTION}" =~ (help|--help) && "${ACTION}" != "debootstrap" ]]; then
	# Make sure we got everything we need to create a customized Ubuntu disc:
	PKGS=()
	whereis mksquashfs | grep -q "/mksquashfs" || PKGS+=( squashfs-tools )
	whereis genisoimage | grep -q "/genisoimage" || PKGS+=( genisoimage )
	whereis xorriso | grep -q "/xorriso" || PKGS+=( xorriso )
	whereis git | grep -q "/git" || PKGS+=( git )
	whereis dialog | grep -q "/dialog" || PKGS+=( dialog )

	# Install any packages that we need for the script to run:
	if [[ ! -z "${PKGS[@]}" ]]; then
		apt update >& /dev/null
		for PKG in ${PKGS[@]}; do
			if apt list ${PKG} 2> /dev/null | grep -qe ${PKG}; then
				_title "Installing ${BLUE}${PKG} package..."
				apt-get install -y $PKG
			else
				_title "${BLUE}${PKG}${GREEN} package not available to install..."
			fi
		done
	fi
fi

#==============================================================================
# Did user request to safely unmount the filesystem mount points?
#==============================================================================
if [[ "${ACTION}" == "update" ]]; then
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_ui_error "Cannot use ${BLUE}update${GREEN} inside chroot environment!"
		exit 1
	elif [[ ! -d ${MUK_DIR}/.git ]]; then
		_ui_error "Unable to update the toolkit because it is not a GitHub repository!"
		exit 1
	fi
	_title "Fetching latest version of this script"
	if [ ! -d ${MUK_DIR} ]; then
		git clone --depth=1 https://github.com/xptsp/modify_ubuntu_kit ${MUK_DIR}
	else
		cd ${MUK_DIR}
		OWNER=($(ls -l | awk '{print $3":"$4}' | sort | uniq | grep -v "root:root" | grep -v "^:$"))
		git reset --hard
		git pull
		[[ ! -z "${OWNER[0]}" ]] && chown -R ${OWNER[0]} *
	fi
	[[ -f ${MUK_DIR}/install.sh ]] && ${MUK_DIR}/install.sh
	_ui_title "Script has been updated to latest version."
	exit 0

#==============================================================================
# Are we changing the unpacked CHROOT environment?
#==============================================================================
elif [[ "${ACTION}" == "mount" ]]; then
	mount | grep -q "${UNPACK_DIR}/edit " && umount ${UNPACK_DIR}/edit
	mount | grep "${UNPACK}/.lower" | awk '{print $3}' | while read DIR; do umount -lfq ${DIR}; rmdir ${DIR}; done
	mkdir -p ${UNPACK_DIR}/{.lower,.upper,.work,edit}
	test -d ${UNPACK_DIR}/extract/live && DIR=live || DIR=casper
	if [[ -f ${UNPACK_DIR}/extract/${DIR}/filesystem.squashfs ]]; then
		mount ${UNPACK_DIR}/extract/${DIR}/filesystem.squashfs ${UNPACK_DIR}/.lower || exit 1
	else
		_ui_error "No \"filesystem.squashfs\" found!  Use ${BLUE}edit_chroot unpack${GREEN} first!"
		exit 1
	fi
	COUNT=0
	cd ${UNPACK_DIR}
	TLOWER=.lower$(ls ${UNPACK_DIR}/extract/casper/filesystem_*.squashfs 2> /dev/null | while read FILE; do
		COUNT=$((COUNT + 1))
		mkdir -p .lower${COUNT}
		mount ${FILE} .lower${COUNT} || exit 1
		echo -n ":.lower${COUNT}"
	done)
	TLOWER=($(echo $TLOWER | sed "s|\:|\n|g" | tac))
	LOWER=$(echo ${TLOWER[@]} | sed "s| |:|g")
	mount -t overlay -o lowerdir=${LOWER},upperdir=${UNPACK_DIR}/.upper,workdir=${UNPACK_DIR}/.work edit_chroot ${UNPACK_DIR}/edit || exit 1
	_ui_title "Necessary chroot filesystem mount points have been mounted!"

#==============================================================================
# Are we changing the unpacked CHROOT environment?
#==============================================================================
elif [[ "${ACTION}" =~ (enter|upgrade|build|debootstrap|sub_rollback) ]]; then
	#==========================================================================
	# Determine if we are working inside or outside the CHROOT environment
	#==========================================================================
	if [[ $(ischroot; echo $?) -eq 1 ]]; then
		#======================================================================
		# RESULT: We are outside the chroot environment:
		#======================================================================
		### First: Make sure that the CHROOT environment actually exists:
		cd ${UNPACK_DIR}
		if [[ "${ACTION}" == "debootstrap" ]]; then
			### Remove current chroot environment, because we are going to start over again:
			test -d ${UNPACK_DIR}/edit && rm -rf ${UNPACK_DIR}/edit 2> /dev/null
			mkdir -p ${UNPACK_DIR}/edit
			$0 remove || exit 1
			mkdir -p ${UNPACK_DIR}/.upper
			mount --bind ${UNPACK_DIR}/.upper ${UNPACK_DIR}/edit

			### Create the chroot environment by debootstrapping it!  Install "debootstrap" if not already installed!
			_title "Building debootstrapped chroot environment..."
			whereis debootstrap | grep -q "/debootstrap" || apt install -y debootstrap
			source /etc/os-release
			DISTRO=${2:-${UBUNTU_CODENAME}}
			ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
			debootstrap --arch=${ARCH} --variant=minbase ${DISTRO:-"${VERSION_CODENAME}"} ${UNPACK_DIR}/edit || exit 1
		else
			$0 unmount
			$0 mount || exit 1
		fi

		## Third: Are we building a particular combination of scripts we have?
		if [[ "${ACTION}" == "build" ]]; then
			valid=($(find ${MUK_DIR}/* -maxdepth 0 -type d | while read DIR; do basename $DIR; done))
			if [[ "$2" != "misc" && ! -z "${valid[$2]}" ]]; then
				# If the "build" choice was made, ask which directory to run through:
				if [[ "${UI}" == "Y" ]]; then
					choice2=(base "Base build" desktop "Desktop build" htpc "HTPC build" docker "Docker build" misc "Miscellaneous build")
					height=$(( ${#choice2[@]} / 2 + 7 ))
					option2=$(dialog --menu "Available Build Packages:" ${height} 40 16  "${choice2[@]}" 2>&1 >/dev/tty)
					[[ -z "${option2}" ]] && clear && exit 1
				fi
				valid="${valid[@]}"
				valid=${valid// /${GREEN}, ${RED}}
				_error "Invalid build specified!  Supported values are: ${RED}${valid}${GREEN}!"
				exit 1
			fi
		fi

		### Third: Update MUK, then setup the CHROOT environment:
		cp /etc/resolv.conf ${UNPACK_DIR}/edit/etc/
		cp /etc/hosts ${UNPACK_DIR}/edit/etc/
		mount --bind /run/ ${UNPACK_DIR}/edit/run
		mount --bind /dev/ ${UNPACK_DIR}/edit/dev
		mount -t tmpfs tmpfs ${UNPACK_DIR}/edit/tmp
		mount -t tmpfs tmpfs ${UNPACK_DIR}/edit/var/cache/apt

		### Fourth: Copy MUK into chroot environment:
		rm -rf ${UNPACK_DIR}/edit/${MUK_DIR}
		cp -aR ${MUK_DIR} ${UNPACK_DIR}/edit/${MUK_DIR}
		chown root:root -R ${UNPACK_DIR}/edit/${MUK_DIR}

		### Fifth: Enter the CHROOT environment:
		_title "Entering CHROOT environment"
		chroot ${UNPACK_DIR}/edit ${MUK_DIR}/edit_chroot.sh $@
		[[ -d ${UNPACK_DIR}/extract/live ]] && DIR=live || DIR=casper
		if [[ -f ${UNPACK_DIR}/edit/usr/local/finisher/build.txt ]]; then
			cp ${UNPACK_DIR}/edit/usr/local/finisher/build.txt ${UNPACK_DIR}/extract/${DIR}/build.txt
		else
			cp ${UNPACK_DIR}/edit/etc/os-release ${UNPACK_DIR}/extract/${DIR}/build.txt
		fi

		### Sixth: Run required commands outside chroot commands:
		if [[ -f ${UNPACK_DIR}/edit/usr/local/finisher/outside_chroot.list ]]; then
			$0 docker_mount
			_title "Executing scripts outside of CHROOT environment..."
			(while read p; do ${UNPACK_DIR}/edit/$p; done) < ${UNPACK_DIR}/edit/usr/local/finisher/outside_chroot.list
			$0 docker_umount
		fi

		### Seventh: Copy the new INITRD from the unpacked filesystem:
		cd ${UNPACK_DIR}/edit
		INITRD=$(ls initrd.img-* 2> /dev/null | tail -1)
		[[ -z "${INITRD}" ]] && INITRD_SRC=$(ls boot/initrd.img-* 2> /dev/null | tail -1)
		if [[ ! -z "${INITRD_SRC}" ]]; then
			# Is this Ubuntu?
			if [[ -f ${UNPACK_DIR}/extract/casper/initrd ]]; then
				_title "Moving ${BLUE}INITRD.IMG${GREEN} from unpacked filesystem from ${BLUE}${INITRD_SRC}${GREEN}..."
				mv ${UNPACK_DIR}/edit/${INITRD_SRC} ${UNPACK_DIR}/extract/casper/initrd
			# Or is this Debian?
			elif [[ -d ${UNPACK_DIR}/extract/live ]]; then
				# Is this the Raspberry Pi OS image?
				if [[ -f ${UNPACK_DIR}/extract/live/vmlinuz0 ]]; then
					VER=$(echo ${INITRD_SRC} | grep -o -e "[0-9]*\.[0-9]*\.[0-9]*\-[0-9]*")
					_title "Moving ${BLUE}INITRD0.IMG${GREEN} from unpacked filesystem from ${BLUE}boot/initrd.img-${VER}-686${GREEN}..."
					mv ${UNPACK_DIR}/edit/boot/initrd.img-${VER}-686 ${UNPACK_DIR}/extract/live/initrd0.img
					_title "Moving ${BLUE}INITRD1.IMG${GREEN} from unpacked filesystem from ${BLUE}boot/initrd.img-${VER}-686-pae${GREEN}..."
					mv ${UNPACK_DIR}/edit/boot/initrd.img-${VER}-686-pae ${UNPACK_DIR}/extract/live/initrd1.img
					_title "Moving ${BLUE}INITRD2.IMG${GREEN} from unpacked filesystem from ${BLUE}boot/initrd.img-${VER}-amd64${GREEN}..."
					mv ${UNPACK_DIR}/edit/boot/initrd.img-${VER}-amd64 ${UNPACK_DIR}/extract/live/initrd2.img
				else
					# Must be just regular Debian:
					_title "Moving ${BLUE}INITRD.IMG${GREEN} from unpacked filesystem from ${BLUE}${INITRD_SRC}${GREEN}..."
					mv ${UNPACK_DIR}/edit/${INITRD_SRC} ${UNPACK_DIR}/extract/live/initrd
				fi
			fi
		fi

		### Eighth: Modify "grub.cfg":
		FILE=$(find ${UNPACK_DIR}/extract -name grub.cfg  -print -quit)
		# NOTE: Rename "initrd.gz" entries only for Ubuntu (and maybe Debian), --NEVER-- Raspberry Pi OS:
		test -f ${UNPACK_DIR}/extract/live/vmlinuz0 || sed -i "s|initrd.gz|initrd|g" ${FILE}

		### Ninth: Copy the new VMLINUZ from the unpacked filesystem:
		VMLINUZ=$(ls vmlinuz-* 2> /dev/null | tail -1)
		[[ -z "${VMLINUZ}" ]] && VMLINUZ=$(ls boot/vmlinuz-* 2> /dev/null | tail -1)
		if [[ ! -z "${VMLINUZ}" ]]; then
			# Is this Ubuntu?
			if [[ -f ${UNPACK_DIR}/extract/casper/initrd ]]; then	# Ubuntu:
				_title "Moving ${BLUE}VMLINUZ${GREEN} from unpacked filesystem from ${BLUE}${VMLINUZ}${GREEN}...."
				mv ${UNPACK_DIR}/edit/${VMLINUZ} ${UNPACK_DIR}/extract/casper/vmlinuz
			# Or is this Debian?
			elif [[ -d ${UNPACK_DIR}/extract/live ]]; then
				# Is this the Raspberry Pi OS image?
				if [[ -f ${UNPACK_DIR}/extract/live/vmlinuz0 ]]; then
					VER=$(echo ${INITRD_SRC} | grep -o -e "[0-9]*\.[0-9]*\.[0-9]*\-[0-9]*")
					_title "Moving ${BLUE}VMLINUZ0${GREEN} from unpacked filesystem from ${BLUE}vmlinuz-${VER}-686${GREEN}...."
					mv ${UNPACK_DIR}/edit/boot/vmlinuz-${VER}-686 ${UNPACK_DIR}/extract/live/vmlinuz0
					_title "Moving ${BLUE}VMLINUZ1${GREEN} from unpacked filesystem from ${BLUE}vmlinuz-${VER}-686-pae${GREEN}...."
					mv ${UNPACK_DIR}/edit/boot/vmlinuz-${VER}-686-pae ${UNPACK_DIR}/extract/live/vmlinuz1
					_title "Moving ${BLUE}VMLINUZ2${GREEN} from unpacked filesystem from ${BLUE}vmlinuz-${VER}-amd64${GREEN}...."
					mv ${UNPACK_DIR}/edit/boot/vmlinuz-${VER}-amd64 ${UNPACK_DIR}/extract/live/vmlinuz2
				else
					# Must be just regular Debian:
					_title "Moving ${BLUE}VMLINUZ${GREEN} from unpacked filesystem from ${BLUE}${VMLINUZ}${GREEN}...."
					mv ${UNPACK_DIR}/edit/${VMLINUZ} ${UNPACK_DIR}/extract/live/vmlinuz
				fi
			fi
		fi

		### Tenth: Remove mounts for CHROOT environment:
		cd ${UNPACK_DIR}
		[[ "${ACTION}" != "sub_rollback" ]] && $0 unmount
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
		export PASSWORD=xubuntu
		export DEBIAN_FRONTEND=noninteractive
		export USER=root
		export SUDO_USER=root
		export KODI_OPT=/opt/kodi
		export KODI_ADD=/etc/skel/.kodi/addons
		export KODI_BASE=http://mirrors.kodi.tv/addons/leia/

		### Second: Build debootstrap environment to start with:
		#[[ "${ACTION}" == "debootstrap" ]] && ACTION=enter		## NOTE: Uncomment this line to skip installing all the packages...
		if [[ "${ACTION}" == "debootstrap" ]]; then
			### Set a custom hostname and  configure apt sources.list:
			source /etc/os-release
			if [[ "${ID}" == "ubuntu" ]]; then
				echo "ubuntu-fs-live" > /etc/hostname
				(
					echo "deb http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME} main restricted universe multiverse"
					echo "deb-src http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME} main restricted universe multiverse"
					echo ""
					echo "deb http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME}-security main restricted universe multiverse"
					echo "deb-src http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME}-security main restricted universe multiverse"
					echo ""
					echo "deb http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME}-updates main restricted universe multiverse"
					echo "deb-src http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME}-updates main restricted universe multiverse"
				) > /etc/apt/sources.list
			else
				echo "debian-fs-live" > /etc/hostname
				(
					echo "deb http://ftp.de.debian.org/debian/ ${VERSION_CODENAME} main non-free non-free-firmware contrib"
					echo "deb-src http://ftp.de.debian.org/debian/ ${VERSION_CODENAME} main non-free non-free-firmware contrib"
					echo ""
					echo "deb http://ftp.de.debian.org/debian/ ${VERSION_CODENAME}-security main non-free non-free-firmware contrib"
					echo "deb-src http://ftp.de.debian.org/debian/ ${VERSION_CODENAME}-security main non-free non-free-firmware contrib"
					echo ""
					echo "deb http://ftp.de.debian.org/debian/ ${VERSION_CODENAME}-updates main non-free non-free-firmware contrib"
					echo "deb-src http://ftp.de.debian.org/debian/ ${VERSION_CODENAME}-updates main non-free non-free-firmware contrib"
				) > /etc/apt/sources.list
			fi

			### Update package list, then install systemd packages:
			apt-get update
			apt-get install -y libterm-readline-gnu-perl systemd-sysv
		fi

		### Third: Configure machine-id and divert:
		dbus-uuidgen > /etc/machine-id
		ln -fs /etc/machine-id /var/lib/dbus/machine-id
		dpkg-divert --local --rename --add /sbin/initctl >& /dev/null
		ln -sf /bin/true /sbin/initctl

		### Fourth: Continue building debootstrap environment:
		if [[ "${ACTION}" == "debootstrap" ]]; then
			### Install packages needed for Live System, as well as the kernel:
			PKGS=($(apt list sudo ubuntu-standard casper discover laptop-detect os-prober network-manager net-tools \
					wireless-tools locales grub-common grub-gfxpayload-lists grub-pc grub-pc-bin grub2-common \
					grub-efi-amd64-signed shim-signed mtools binutils tasksel 2> /dev/null | sed '1d' | cut -d/ -f 1))
			apt install -y ${PKGS[@]}
   			apt-get install -y --no-install-recommends linux-generic

			### Change "action" variable to "enter", so we can continue to modify the chroot environment:
   			ACTION=enter
   		fi

		### Fifth: Install the chroot tools if required, then put firefox on hold if it is still snap version:
		test -f ${MUK_DIR}/install.sh && source ${MUK_DIR}/install.sh
		if grep -q "ID=ubuntu" /etc/os-release; then
			if ! apt-mark showhold | grep -q firefox; then apt list --installed firefox 2> /dev/null | grep -q 1snap1 && apt-mark hold firefox > /dev/null; fi
		fi
		test -e /usr/local/bin/cls || ln -sf /usr/bin/clear /usr/local/bin/cls

		### Sixth: Next action depends on parameter passed....
		if [[ "${ACTION}" == "enter" ]]; then
			### "enter": Create a bash shell for user to make alterations to chroot environment
			clear
			_title "Ready to modify CHROOT environment!"
			echo -e "${RED}NOTE: ${GREEN}Enter ${BLUE}exit${GREEN} to exit the CHROOT environment"
			echo -e ""
			echo "CHROOT" > /etc/debian_chroot
			echo ". ${INC_SRC}" >> /etc/skel/.bashrc
			bash -s
			cat /etc/skel/.bashrc | grep -v "${INC_SRC}" > /tmp/.bashrc
			mv /tmp/.bashrc /etc/skel/.bashrc
			[ -f /etc/debian_chroot ] && rm /etc/debian_chroot
			clear
		elif [[ "${ACTION}" == "build" ]]; then
			### "build": Install all scripts found in the specified build folder:
			cd ${MUK_DIR}/$2
			for file in *.sh; do ./$file; done
		elif [[ "${ACTION}" == "sub_rollback" ]]; then
			### "sub_rollback": Reinstall kernel and regenerate initramfs:
			_title "Reinstalling kernel..."
			KERNEL=$(apt list --installed linux-image-* 2> /dev/null | cut -d/ -f 1 | grep -m 1 linux-image | grep -v generic-hwe)
			apt install --reinstall ${KERNEL}
			_title "Recreating initramfs..."
			update-initramfs -c -k ${KERNEL/linux-image-/}
		fi

		### Seventh: If user 999 exists, change that user ID so that LiveCD works:
		uid_name=$(grep ":999:" /etc/passwd | cut -d":" -f 1)
		if [[ ! -z "${uid_name}"  ]]; then
			uid_new=998
			while [ "$(id -u ${uid_new} >& /dev/null; echo $?)" -eq 0 ]; do uid_new=$((uid_new-1)); done
			_title "Changing user \"${uid_name}\" from UID 999 to ${uid_new} so LiveCD works..."
			usermod -u ${uid_new} ${uid_name}
			chown -Rhc --from=999 ${uid_new} / >& /dev/null
		fi

		### Eighth: If group 999 exists, change that group ID so that LiveCD works:
		gid_line=$(getent group 999)
		if [[ ! -z "${gid_line}" ]]; then
			gid_name=$(echo $gid_line | cut -d":" -f 1)
			gid_new=998
			while [ "$(getent group ${gid_new} >& /dev/null; echo $?)" -eq 0 ]; do gid_new=$((gid_new-1)); done
			_title "Changing group \"${gid_name}\" from GID 999 to ${gid_new} so LiveCD works..."
			groupmod -g ${gid_new} ${gid_name}
			chown -Rhc --from=:999 :${gid_new} / >& /dev/null
		fi

		### Ninth: Upgrade the installed GitHub repositories:
		_title "Updating GitHub repositories in ${BLUE}/opt${GREEN}..."
		cd /opt
		(ls | while read p; do pushd $p; [ -d .git ] && git pull; popd; done) >& /dev/null

		### Tenth: Upgrade the pre-installed Kodi addons via GitHub repositories:
		if [ -d /opt/kodi ]; then
			_title "Updating Kodi addons from GitHub repositories in ${BLUE}/opt/kodi${GREEN}...."
			pushd /opt/kodi >& /dev/null
			(ls | while read p; do pushd $p; [ -d .git ] && git pull; popd; done) >& /dev/null
			popd >& /dev/null
		fi

		### Eleventh: Update packages:
		_title "Updating repository lists...."
		apt-get update >& /dev/null
		_title "Upgrading any packages requiring upgrading..."
		apt-get upgrade -y

		### Twelveth: Purge older kernels from the image:
		if [[ "${OLD_KERNEL}" -eq 1 ]]; then
			_title "Removing any older kernels from the image..."
			CUR=$(ls -l /boot/initrd.img 2> /dev/null | awk '{print $NF}' | grep -o -e "[0-9]*\.[0-9]*\.[0-9]*\-[0-9]*")
			[[ -z "${CUR}" ]] && CUR=$(ls /boot/initrd.img-* | tail -1 | grep -o -e "[0-9]*\.[0-9]*\.[0-9]*\-[0-9]*")
			for VER in $(apt list linux-image-* --installed 2> /dev/null | grep linux-image | cut -d/ -f 1 | grep -o -e "[0-9]*\.[0-9]*\.[0-9]*\-[0-9]*" | sort | uniq); do
				[[ "$VER" != "${CUR}" ]] && apt purge -y $(apt list --installed linux-*${VER}* 2> /dev/null | grep linux- | cut -d\/ -f 1)
			done
		fi

		### Fourteenth: Remove any unnecessary packages and fix any broken packages:
		_title "Removing unnecessary packages and fixing any broken packages..."
		apt-get install -f --autoremove --purge -y

		### Fifteenth: Remove any unnecessary packages:
		_title "Cleaning up cached packages..."
		apt-get autoclean -y >& /dev/null
		apt-get clean -y >& /dev/null

		### Sixteenth: Disable services not required during Live ISO:
		if [[ -f /usr/local/finisher/disabled.list ]]; then
			_title "Disabling unnecessary services for Live CD..."
			(while read p r; do systemctl disable $p; done) < /usr/local/finisher/disabled.list >& /dev/null
		fi

		### Seventeenth: Clean up everything done to "chroot" into this ISO image:
		_title "Undoing CHROOT environment modifications..."
		if apt-mark showhold | grep -q firefox; then apt list firefox 2> /dev/null | grep -q 1snap1 && apt-mark unhold firefox > /dev/null; fi
		test -d /etc/sudoers.d && chmod 440 /etc/sudoers.d/*
		rm -rf /tmp/* ~/.bash_history
		truncate -s 0 /etc/machine-id
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
elif [[ "${ACTION}" == "unmount" ]]; then
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_ui_error "Cannot use ${BLUE}unmount${GREEN} inside chroot environment!"
		exit 1
	fi
	_title "Unmounting filesystem mount points...."
	umount -qlf ${UNPACK_DIR}/edit/tmp/host >& /dev/null
	mount | grep "${UNPACK_DIR}/edit" | awk '{print $3}' | tac | while read DIR; do umount -qlf ${DIR}; done
	mount | grep "${UNPACK_DIR}/.lower" | awk '{print $3}' | while read DIR; do umount -qlf ${DIR} 2> /dev/null; test -d ${DIR} && rmdir ${DIR}; done
	$0 docker_umount -q
	_ui_title "All filesystem mount points should be unmounted now."

#==============================================================================
# Did user request to safely remove the unpacked filesystem?
#==============================================================================
elif [[ "${ACTION}" == "remove" ]]; then
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_ui_error "Cannot use ${BLUE}remove${GREEN} inside chroot environment!"
		exit 1
	elif [[ ! -d ${UNPACK_DIR}/edit ]]; then
		_ui_error "No unpacked filesystem!  Use ${BLUE}edit_chroot unpack${GREEN} first!"
		exit 1
	fi
	$0 unmount
	_title "Removing modifications to squashfs..."
	umount -q ${UNPACK_DIR}/edit
	test -d ${UNPACK_DIR}/.upper && rm -rf ${UNPACK_DIR}/.upper
	_ui_title "Modifications to squashfs filesystem has been removed."

#==============================================================================
# Did user request to unpack the ISO?
#==============================================================================
elif [[ "${ACTION}" == "unpack" ]]; then
	# First: Make sure everything is okay before proceeding:
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_ui_error "Cannot use ${BLUE}unpack${GREEN} inside chroot environment!"
		exit 1
	fi
	cd ${UNPACK_DIR}
	mkdir -p mnt
	umount -q mnt
	ISO=$2
	if [[ -z "$ISO" ]]; then
		if mount /dev/cdrom ${UNPACK_DIR}/mnt; then
			_ui_error "No DVD in the drive!"
			exit 1
		fi
	else
		if ! mount -o loop -r $ISO ${UNPACK_DIR}/mnt >& /dev/null; then
			_ui_error "Specified ISO unable to be mounted!"
			exit 1
		fi
	fi
	if [[ ! -f mnt/casper/filesystem.squashfs && ! -f mnt/live/filesystem.squashfs ]]; then
		_ui_error "Cannot find a ${BLUE}filesystem.squashfs${GREEN} to extract!!!"
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
	_ui_title "Ubuntu ISO has been unpacked!"

#==============================================================================
# Did user request to pack the chroot environment?
#==============================================================================
elif [[ "${ACTION}" =~ (pack|changes)(-xz|) ]]; then
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_ui_error "Cannot use ${BLUE}pack${GREEN} inside chroot environment!"
		exit 1
	elif [[ ! -d ${UNPACK_DIR}/extract ]]; then
		_ui_error "No ISO structure created!  Use ${BLUE}edit_chroot unpack${GREEN} first!"
		exit 1
	elif [[ ! -d ${UNPACK_DIR}/edit ]]; then
		_ui_error "No unpacked filesystem!  Use ${BLUE}edit_chroot unpack${GREEN} first!"
		exit 1
	fi

	# First: Prep the unpacked filesystem to be packaged:
	cd ${UNPACK_DIR}
	$0 unmount
	$0 mount || exit 1
	[ -f ${UNPACK_DIR}/edit/etc/debian_chroot ] && rm ${UNPACK_DIR}/edit/etc/debian_chroot

	# Second: Call "sub_manifest" routine to build particular files required:
	$0 sub_manifest

	# Third: Set necessary flags for compression:
	[[ "${ACTION}" =~ -xz$ ]] && FLAG_XZ=1
	XZ=$([[ ${FLAG_XZ:-"0"} == "1" ]] && echo "-comp xz -Xdict-size 100%")

	# Fourth: Pack the filesystem into squashfs if required:
	[[ "${ACTION}" == "pack" || "${ACTION}" == "pack-xz" ]] && SRC=edit || SRC=.upper
	FS=filesystem_$(date +"%Y%m%d")
	FS=${FS}-$(( $(ls -r extract/${DIR}/${FS}-* 2> /dev/null | grep -m 1 -oe "$FS-[0-9]" | cut -d- -f 2 | cut -d_ -f 1) + 1 ))
	eval `grep -m 1 -e "^MUK_COMMENT=" edit/etc/os-release && sed -i "/^MUK_COMMENT=/d" edit/etc/os-release`
	[[ ! -z "${2}" ]] && MUK_COMMENT=$2
	[[ ! -z "${MUK_COMMENT}" ]] && FS=${FS}_${MUK_COMMENT}
	test -d extract/live && DIR=live || DIR=casper

	FS=${FS}.squashfs
	_title "Building ${BLUE}${FS}${GREEN}...."
	mksquashfs ${SRC} extract/${DIR}/${FS} -b 1048576 ${XZ}

	# Fifth: Generate a GPG signature for the squashfs we just created:
	unset KEY
	let i=0
	KEYS=()
	while read -r KEY; do
		let i=$i+1
		KEYS+=($i "${KEY}")
	done <<< $(sudo -u ${SUDO_USER} gpg -K | grep "^uid" | cut -d] -f 2- | sed "s|^\s||")
	if [[ "${#KEYS[@]}" -gt 0 ]]; then
		if [[ ${#KEYS[@]} -eq 2 ]]; then
			KEY=${KEYS[1]}
		else
			VAL=$(dialog --erase-on-exit --cancel-label "No Signature" --ok-label "Select" --title "Key Selection Dialog" --menu "Choose a GPG Key:" $(( ${#KEYS[@]} / 2 + 7 )) 60 17 "${KEYS[@]}" 3>&2 2>&1 1>&3)
			[[ ! -z "${VAL}" ]] && KEY=${KEYS[ $(( VAL * 2 - 1 )) ]}
		fi
	fi
	if [[ ! -z "${KEY}" ]]; then
		_title "Signing ${BLUE}${FS}${GREEN}...."
		sudo -u ${SUDO_USER} gpg -v -u "${KEY}" -o extract/${DIR}/${FS}.gpg -b extract/${DIR}/${FS}
		chown root:root extract/${DIR}/${FS}.gpg
	fi

	# Sixth: remove the overlay filesystem and upper layer of overlay, then create the "md5sum.txt" file:
	_title "Removing the overlay filesystem and upper layer of overlay..."
	$0 remove
	if [[ "${ACTION}" == "pack" || "${ACTION}" == "pack-xz" ]]; then
		mv ${UNPACK_DIR}/extract/${DIR}/${FS} ${UNPACK_DIR}/extract/${DIR}/filesystem.squashfs
		test -f ${UNPACK_DIR}/extract/${DIR}/${FS}.gpg && mv ${UNPACK_DIR}/extract/${DIR}/${FS}.gpg ${UNPACK_DIR}/extract/${DIR}/filesystem.squashfs.gpg
		rm ${UNPACK_DIR}/extract/${DIR}/filesystem_*.squashfs* 2> /dev/null
	fi

	# Seventh: Create MD5 checksum file:
	$0 sub_md5sum

	# Eighth: Tell user we done!
	_ui_title "Done packing and preparing extracted filesystem!"

#==============================================================================
# Pack subroutine: Create manifest and filesystem size files:
#==============================================================================
elif [[ "${ACTION}" == "sub_manifest" ]]; then
	# First, build the list of installed packages in unpacked filesystem:
	cd ${UNPACK_DIR}
	_title "Building list of installed packages...."
	if [[ -d extract/live ]]; then DIR=live; EXT=packages; else DIR=casper; EXT=manifest; EXT2=-desktop; fi
	chmod +w extract/${DIR}/filesystem.${EXT} >& /dev/null
	chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract/${DIR}/filesystem.${EXT}
	[[ -f extract/${DIR}/filesystem.${EXT}${EXT2} ]] && cp extract/${DIR}/filesystem.${EXT} extract/${DIR}/filesystem.${EXT}${EXT2} || EXT2=
	sed -i '/ubiquity/d' extract/${DIR}/filesystem.${EXT}${EXT2}
	sed -i '/casper/d' extract/${DIR}/filesystem.${EXT}${EXT2}
	sed -i '/discover/d' extract/${DIR}/filesystem.${EXT}${EXT2}
	sed -i '/laptop-detect/d' extract/${DIR}/filesystem.${EXT}${EXT2}
	sed -i '/os-prober/d' extract/${DIR}/filesystem.${EXT}${EXT2}

	# Then create the "filesystem.size" file:
	_title "Updating ${BLUE}filesystem.size${GREEN}...."
	du -s --block-size=1 edit | cut -f1 > extract/${DIR}/filesystem.size

#==============================================================================
# Pack subroutine: Create md5 checksum file:
#==============================================================================
elif [[ "${ACTION}" == "sub_md5sum" ]]; then
	_title "Creating the \"md5sum.txt\" file..."
	cd ${UNPACK_DIR}/extract
	[ -f md5sum.txt ] && rm md5sum.txt
	find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.txt >& /dev/null

#==============================================================================
# Did user request to create the ISO?
#==============================================================================
elif [[ "${ACTION}" == "iso" ]]; then
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_ui_error "Cannot use ${BLUE}iso${GREEN} inside chroot environment!"
		exit 1
	elif [[ ! -d ${UNPACK_DIR}/extract ]]; then
		_ui_error "No ISO structure copied!  Use ${BLUE}edit_chroot unpack${GREEN} first!"
		exit 1
	elif [[ ! -f ${UNPACK_DIR}/extract/casper/filesystem.squashfs && ! -f ${UNPACK_DIR}/extract/live/filesystem.squashfs ]]; then
		_ui_error "No packed filesystem!  Use ${BLUE}edit_chroot pack${GREEN} first!"
		exit 1
	fi

	# First: Read either the OS's "build.txt" file OR the "os-release":
	ISO_DIR=${UNPACK_DIR}
	unset MUK_BUILD
	[[ -d ${UNPACK_DIR}/extract/live ]] && DIR=live || DIR=casper
	if [[ -f ${UNPACK_DIR}/extract/${DIR}/build.txt ]]; then
		source ${UNPACK_DIR}/extract/${DIR}/build.txt
	elif [[ -f ${UNPACK_DIR}/edit/etc/os-release ]]; then
		source ${UNPACK_DIR}/edit/etc/os-release
	else
		source /etc/os-release
	fi

	# Second: Figure out what to name the ISO to avoid conflicts
	_title "Determining ISO filename...."
	if [[ -f ${UNPACK_DIR}/extract/live/vmlinuz0 ]]; then
		NAME=raspios
		ISO_FILE=${NAME}-${VERSION_CODENAME}-i386-$(date +"%Y-%m-%d")
		FLAG_ADD_DATE=0
	else
		ISO_FILE=${ID}-$(echo ${VERSION} | cut -d" " -f 1)-${MUK_BUILD:-"desktop-amd64"}
	fi
	ISO_FILE=${ISO_FILE,,}
	[[ "${FLAG_ADD_DATE}" == "1" ]] && ISO_FILE=${ISO_FILE}-$(date +"%Y%m%d")
	if [[ -f "${ISO_DIR}/${ISO_FILE}.iso" ]]; then
		ISO_FILE=${ISO_FILE}-$(( $(ls ${ISO_DIR}/${ISO_FILE}-* | sed "s|${ISO_DIR}/${ISO_FILE}-||" | sed "s|\.iso||" | sort -n | tail -1) + 1 ))
	fi

	# Third: Try to patch grub.cfg for successful LiveCD boot.  Why this is necessary is beyond me.....
	FILE=$(find ${UNPACK_DIR}/extract -name grub.cfg  -print -quit)
	sed -i "s|boot=casper ||g" ${FILE}
	sed -i "s|file=|boot=casper file=|g" ${FILE}

	# Fourth: Fix the ISO identification for Casper Installer:
	FILE=${UNPACK_DIR}/extract/.disk/info
	test -f ${FILE} && echo "${NAME} ${VERSION} - Release amd64 ($(date +"%Y%m%d"))" > ${FILE}

	# Fifth: Create the ISO
	_title "Building ${BLUE}${ISO_FILE}.iso${GREEN}...."
	OLD=N
	[[ "${ID}" == "debian" && "${VERSION_ID/\./}" -lt 12 ]] && OLD=Y
	[[ "${ID}" == "ubuntu" && "${VERSION_ID/\./}" -lt 2204 ]] && OLD=Y
	if [[ "${OLD}" == "Y" ]]; then
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
		NAME=${NAME,,}
		if [[ ! -f ${UNPACK_DIR}/${NAME}_hybrid.img || ! -f ${UNPACK_DIR}/${NAME}_efi.img ]]; then
			$0 sub_efi $(ls ${UNPACK_DIR}/${NAME}-*.iso 2> /dev/null| head -1) || exit 1
		fi
		IMG=/boot/grub/i386-pc/eltorito.img
		if [[ ! -f ${UNPACK_DIR}/extract/${IMG} ]]; then
			IMG=/boot/grub/efi.img
			if [[ ! -f ${UNPACK_DIR}/extract/${IMG} ]]; then _ui_error "No EFI image file found!  Aborting!"; exit 1; fi
		fi

		# Finally pack up an ISO the new way:
		xorriso -as mkisofs -r \
  			-V "${PRETTY_NAME}" \
			-J -joliet-long -iso-level 3 \
  			-o ${ISO_DIR}/${ISO_FILE}.iso \
  			--grub2-mbr ${UNPACK_DIR}/${NAME}_hybrid.img \
  			-partition_offset 16 \
  			--mbr-force-bootable \
  			-append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b ${UNPACK_DIR}/${NAME}_efi.img \
  			-appended_part_as_gpt \
  			-iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  			-c '/boot.catalog' \
  			-b ${IMG} \
				-no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  			-eltorito-alt-boot \
  			-e '--interval:appended_partition_2:::' \
				-no-emul-boot \
			${UNPACK_DIR}/extract
	fi

	# Sixth: Tell user we done!
	_ui_title "Done building ${BLUE}${ISO_DIR}/${ISO_FILE}.iso${GREEN}!"

#==============================================================================
# Did user request to rebuild the filesystem.squashfs and the ISO together?
#==============================================================================
elif [[ "${ACTION}" == "sub_efi" ]]; then
	ISO=$2
	if [[ -z "${ISO}" ]]; then _ui_error "No ISO specified!  Aborting!"; exit 1; fi
	if [[ ! -f "${ISO}" ]]; then _ui_error "Specified ISO ${BLUE}${ISO}${NC} not found!  Aborting!"; exit 1; fi
	NAME=$3
	NAME=${NAME:=$(basename $ISO | cut -d\- -f 1)}

	# Extract the EFI partition image image for -append_partition:
	INFO=($(fdisk -l ${ISO} | grep "EFI"))
	if [[ -z "${INFO}" ]]; then _ui_error "No EFI filesystem present in ISO!  Aborting!"; exit 1; fi
	dd if=${ISO} bs=512 skip=${INFO[1]} count=${INFO[3]} of=${UNPACK_DIR}/${NAME}_efi.img

	# Extract hybrid MBR code:
	dd if=${ISO} bs=1 count=432 of=${UNPACK_DIR}/${NAME}_hybrid.img

#==============================================================================
# Did user request to rebuild the filesystem.squashfs and the ISO together?
#==============================================================================
elif [[ "${ACTION}" == "rebuild" ]]; then
	$0 pack $2 && $0 iso $2
elif [[ "${ACTION}" == "rebuild-xz" ]]; then
	$0 pack-xz $2 && $0 iso $2

#==============================================================================
# Did user request to mount chroot environment docker folder to host machine?
#==============================================================================
elif [[ "${ACTION}" == "docker_mount" ]]; then
	_title "Mounting chroot docker directory on live system:"

	# Create the necessary directories:
	[[ ! -d ${UNPACK_DIR}/edit/var/lib/docker ]] && mkdir -p ${UNPACK_DIR}/edit/var/lib/docker && chmod 722 ${UNPACK_DIR}/edit/var/lib/docker
	[[ ! -d /var/lib/docker ]] && mkdir -p /var/lib/docker

	# Stop docker, mount docker directory inside chroot environment, then start docker:
	systemctl stop docker
	mount --bind $UNPACK_DIR/edit/var/lib/docker /var/lib/docker
	systemctl start docker

#==============================================================================
# Did user request to unmount chroot environment docker folder from host machine?
#==============================================================================
elif [[ "${ACTION}" == "docker_umount" ]]; then
	# If the docker folder doesn't exist, exit the script:
	[[ ! -d ${UNPACK_DIR}/edit/var/lib/docker ]] && exit

	# Generate a random file to check for mounted volume:
	ID=$(cat /dev/urandom | tr -cd 'a-zA-Z0-9' | head -c 32)
	touch ${UNPACK_DIR}/edit/var/lib/docker/${ID} >& /dev/null

	# Does our random file exist in both places?  If not, then it's not mounted:
	MOUNT=$([[ -f /var/lib/docker/${ID} ]] && echo "Y")
	[[ -f ${UNPACK_DIR}/edit/var/lib/docker/${ID} ]] && rm ${UNPACK_DIR}/edit/var/lib/docker/${ID}
	if [[ -z "${MOUNT}" ]]; then
		[[ ! "$2" == "-q" ]] && _ui_error "Docker directory in chroot environment is not mounted on host system!"
		exit 2
	fi

	# Unmount the chroot environment docker directory:
	_ui_title "Unmounting chroot docker directory from live system:"
	systemctl stop docker
	umount -q /var/lib/docker
	systemctl start docker

#==============================================================================
# Mount my Ubuntu split-partition USB stick properly:
#==============================================================================
elif [[ "${ACTION}" == "usb_mount" ]]; then
	UB=$(blkid | grep "${USB_LIVE}" | cut -d: -f 1)
	RO=$(blkid | grep "${USB_CASPER}" | cut -d: -f 1)
	if [[ -z "${UB}" ]]; then _ui_error "No USB EFI partition 1 found! (Ref: \"$USB_LIVE\")"; exit 1; fi
	if [[ -z "${RO}" ]]; then _ui_error "No USB Casper partition 2 found! (Ref: \"$USB_CASPER\")"; exit 1; fi
	if mount | grep -q ${UNPACK_DIR}/mnt; then umount -q ${UNPACK_DIR}/mnt || exit 1; fi
	mount | grep -q ${UNPACK_DIR}/mnt && umount -lfq ${UNPACK_DIR}/mnt
	mkdir -p ${UNPACK_DIR}/usb_{efi,casper} ${UNPACK_DIR}/mnt
	if mount | grep -q ${UB}; then umount -q ${UB} || exit 1; fi
	mount ${UB} ${UNPACK_DIR}/usb_efi -t vfat -o noatime,rw,nosuid,nodev,relatime,uid=1000,gid=1000,fmask=0111,dmask=0022 || exit 1
	if mount | grep -q ${RO}; then umount -q ${RO} || exit 1; fi
	eval `blkid ${RO} -o export`
	mount ${RO} ${UNPACK_DIR}/usb_casper -t ${TYPE} -o defaults,noatime || exit 1
	unionfs ${UNPACK_DIR}/usb_casper=RW:${UNPACK_DIR}/usb_efi=RW ${UNPACK_DIR}/mnt -o default_permissions,allow_other,use_ino,nonempty,suid || exit 1
	_ui_title "Finished mounting split-partition USB stick!"

#==============================================================================
# Unmount my Ubuntu split-partition USB stick properly:
#==============================================================================
elif [[ "${ACTION}" == "usb_unmount" ]]; then
	if mount | grep -q " ${UNPACK_DIR}/mnt "; then umount ${UNPACK_DIR}/mnt || exit 1; fi
	if mount | grep -q " ${UNPACK_DIR}/usb_efi "; then umount ${UNPACK_DIR}/usb_efi || exit 1; fi
	if mount | grep -q " ${UNPACK_DIR}/usb_casper "; then umount ${UNPACK_DIR}/usb_casper || exit 1; fi
	rmdir ${UNPACK_DIR}/usb_{efi,casper} 2> /dev/null
	_ui_title "Split-partition USB stick successfully unmounted!"

#==============================================================================
# Copy "extract" folder <<TO>> my Ubuntu split-partition USB stick:
#==============================================================================
elif [[ "${ACTION}" == "usb_load" ]]; then
	DEV=$(mount | grep "${UNPACK_DIR}/usb_casper" | cut -d" " -f 1)
	if [[ -z "${DEV}" ]]; then $0 usb_mount || exit 1; fi
	cp -R --verbose --update ${UNPACK_DIR}/extract/casper* ${UNPACK_DIR}/mnt/casper/
	eval `blkid -o export ${DEV}`
	FILE=$(find ${UNPACK_DIR}/mnt -name grub.cfg  -print -quit)
	sed -i "s| boot=casper||" ${FILE}
	sed -i "s| live-media=/dev/disk/by-uuid/[0-9a-z\-]*||" ${FILE}
	sed -i "s|vmlinuz |vmlinuz boot=casper live-media=/dev/disk/by-uuid/${UUID} |" ${FILE}
	_ui_title "File copy to split-partition USB stick completed!"

#==============================================================================
# Copy <<FROM>> my Ubuntu split-partition USB stick to "extract" folder:
#==============================================================================
elif [[ "${ACTION}" == "usb_copy" ]]; then
	DEV=$(mount | grep "${UNPACK_DIR}/usb_casper" | cut -d" " -f 1)
	if [[ -z "${DEV}" ]]; then $0 usb_mount || exit 1; fi
	cp -R --verbose --update ${UNPACK_DIR}/mnt/casper* ${UNPACK_DIR}/extract/casper
	FILE=$(find ${UNPACK_DIR}/extract -name grub.cfg  -print -quit)
	sed -i "s| live-media=/dev/disk/by-uuid/[0-9a-z\-]*||g" ${FILE}
	_ui_title "File copy from split-partition USB stick completed!"

#==============================================================================
# Update snap configuration)
#==============================================================================
elif [[ "${ACTION}" == "snap" ]]; then
	$0 unmount
	$0 mount || exit 1

	_title "Disabling current snaps...."
	SNAPS=($(snap list --all 2> /dev/null | awk '{print $1}' | sed "/^Name$/d"))
	for SNAP in ${SNAPS[@]}; do snap disable ${SNAP}; done

	_title "Unmounting snap-related directories..."
	mount | grep "/var/snap" | awk '{print $3}' | while read DIR; do umount ${DIR}; done

	_title "Removing current snaps..."
	while true; do
		LIST=($(snap list --all 2> /dev/null | awk '{print $1}' | sed "/^Name$/d"))
		[[ -z "${LIST[@]}" ]] && break
		for SNAP in ${LIST[@]}; do snap remove ${SNAP}; done
	done

	_title "Purging \"snapd\" package and settings..."
	apt purge -y snapd
	rm -rf /var/{snap,lib/snap,lib/snapd} /etc/systemd/system/snap*

	_title "Reinstalling \"snapd\" package..."
	apt install -y snapd

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
		fi
		FILE=$(basename ${SNAP}_*.snap)
		grep -q "${FILE}" ${YAML} || (echo -e "\t-"; echo -e "\t\tname: ${SNAP}"; echo -e "\t\tchannel: stable"; echo -e "\t\tfile: ${FILE}") >> ${YAML}
	done

	_title "Stopping Snap service..."
	systemctl stop snapd
	systemctl mask snapd
	systemctl disable snapd

	# Replace existing snap directories with those from the casper-rw partition:
	_title "Replacing snap directories..."
	EDIT=${UNPACK_DIR}/edit
	rm -rf ${EDIT}/var/lib/snapd
	cp -aR /var/lib/snapd ${EDIT}/var/lib/
	rm -rf ${EDIT}/var/snap
	cp -aR /var/snap ${EDIT}/var/
	rm -rf ${EDIT}/snap
	cp -aR /snap ${EDIT}/
	for SNAP in /var/lib/snapd/snaps/*.snap; do
		ln ${SNAP} ${SNAP/snaps/seed\/snaps}
		ln ${EDIT}/${SNAP} ${EDIT}/${SNAP/snaps/seed\/snaps}
	done

	_title "Restarting Snap service..."
	systemctl unmask snapd
	systemctl enable snapd
	systemctl start snapd
	rm -rf ${EDIT}/etc/systemd/system/snap*
	cp -aR /etc/systemd/system/snap* ${EDIT}/etc/systemd/system/ 2> /dev/null

	# Tell user we're finished:
	_ui_title "Completed rebuilding chroot environment snap configuration!"

#==============================================================================
# Revert chroot environment back one squashfs package:
# NOTE: Requires multiple squashfs files in the "casper" directory!
#==============================================================================
elif [[ "${ACTION}" == "rollback" ]]; then
	LAST=$(ls -r ${UNPACK_DIR}/extract/casper/filesystem_* | head -1)
	if [[ -z "${LAST}" ]]; then _ui_error "No squashfs files starting with ${BLUE}filesystem_${GREEN} found!  Aborting!"; exit 1; fi
	if [[ "$2" != "-y" && "$2" != "--yes" ]]; then
		dialog --stdout --title "Confirm Deletion" --defaultno --yesno "Delete $(basename ${FILE})?\n\nThis action cannot be undone!" 7 60 || exit 0
	fi

	# Remove filesystem changes, then get kernel files and generate initramfs:
	$0 remove
	$0 unmount
	rm ${LAST} || exit 1
	$0 sub_rollback
	$0 sub_manifest
	$0 sub_md5sum
	$0 remove
	_title "Rolled back ${BLUE}$(basename ${FILE})${GREEN} from chroot environment!"

#==============================================================================
# Invalid parameter specified.  List available parameters:
#==============================================================================
elif [[ ! -z "${ACTION}" ]]; then
	[[ ! "${ACTION}" == "--help" ]] && echo "Invalid parameter specified!"
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
	echo -e "  ${GREEN}mount${NC}          Mounts all unpacked filesystem mount points."
	echo -e "  ${GREEN}unmount${NC}        Safely unmounts all unpacked filesystem mount points."
	echo -e "  ${GREEN}remove${NC}         Safely removes the unpacked filesystem from the hard drive."
	echo -e "  ${GREEN}update${NC}         Updates this script with the latest version."
	echo -e "  ${GREEN}debootstrap${NC}    Build a new chroot environment using debootstrap tool."
	echo -e "  ${GREEN}snap${NC}           Rebuilds snap directories with latest versions of each snap."
	echo -e "  ${GREEN}rollback${NC}       Rollback a single non-\"filesystem.squashfs\" squashfs file."
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

#==============================================================================
# No command-line option specified!  Show the menu:
#==============================================================================
else
	while true; do
		# Present the available options to the user.  Exit if no choice made:
		choices=(
			enter       "Enter the unpacked filesystem environment to make changes."
			unpack      "Copies the Ububuntu installer files from DVD/ISO on hard drive"
			pack        "Packs the unpacked filesystem."
			changes     "Packs the CHANGES to the unpacked filesystem ."
			iso         "Builds an ISO containing the packed filesystem."
			rebuild     "Combines the \"pack\" and \"iso\" operations."
			build       "Enter unpacked filesystem environment to install specified packages."
			upgrade     "Only upgrades Ubuntu packages with any updates available."
			mount       "Mounts all unpacked filesystem mount points."
			unmount     "Safely unmount all unpacked filesystem mount points."
			debootstrap "Build a new chroot environment using debootstrap tool."
		)
		height=$(( ${#choices[@]} / 2 + 7 ))
		unset option2
		choice=$(dialog --menu "Available \"edit_chroot\" options:" ${height} 80 16  "${choices[@]}" 2>&1 >/dev/tty)
		[[ -z "$choice" ]] && break

		# If the "pack", "changes", or "reubild" choice was made, ask about XZ compression:
		if [[ "$choice" =~ (pack|changes|rebuild) ]]; then
			choice=${choice}$(dialog --yesno "Use XZ compression?" 10 40 2>&1 >/dev/tty && echo "-xz")
		fi

		# Clear the screen, then call itself to do the choice:
		clear
		$0 ${choice}-ui ${option2}
	done
	clear
fi
[[ "${ACTION}" =~ (usb_|docker_|)(un|)mount || "${ACTION}" =~ ^sub_ ]] || echo -e ""
