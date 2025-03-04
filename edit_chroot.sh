#!/bin/bash

###############################################################################
# Script settings and their defaults:
###############################################################################
# If exists, load the user settings into the script:
[[ -f /usr/local/finisher/settings.conf ]] && source /usr/local/finisher/settings.conf
[[ -f /etc/default/edit_chroot ]] && source /etc/default/edit_chroot
# Flag: Defaults to adding date ISO was generated to end of ISO name.  Set to 0 to prevent this.
FLAG_ADD_DATE=${FLAG_ADD_DATE:-"1"}
# Flag: Use XZ (value: 1) instead of GZIP (value: 0) compression.  Defaults to 0:
FLAG_XZ=${FLAG_XZ:-"0"}
# Flag: Use MKIFOFS (value: 1) instead of GENISOIMAGE (value: 0).  Defaults to 0.
FLAG_MKISOFS=${FLAG_MKISOFS:-"0"}
# Where to place extracted and chroot environment directories.  Defaults to "/img".
UNPACK_DIR=${UNPACK_DIR:-"/home/img"}
# Where to place the generated ISO file.  Defaults to current directory.
ISO_DIR=${ISO_DIR:-"${UNPACK_DIR}"}
# Default to removing old kernels from chroot environment.  Set to 0 to prevent this.
OLD_KERNEL=${OLD_KERNEL:-"1"}
# Determine ISO version number to use:
[[ -f ${UNPACK_DIR}/edit/etc/os-release ]] && ISO_VERSION=$(grep "VERSION=" ${UNPACK_DIR}/edit/etc/os-release | cut -d "\"" -f 2 | cut -d " " -f 1)
# MUK path:
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
# Custom USB Stick partition #1 identification:
USB_LIVE=${USB_LIVE:-"LABEL=\"UBUNTU_EFI\""}
USB_LIVE=$(echo ${USB_LIVE} | cut -d= -f 1)=\"$(echo ${USB_LIVE} | cut -d= -f 2 | sed "s|\"||g")\"
# Custom USB Stick partition #2 identification:
USB_CASPER=${USB_CASPER:-"LABEL=\"UBUNTU_CASPER\""}
echo ${USB_CASPER} | grep -q "=" && USB_CASPER=$(echo ${USB_CASPER} | cut -d= -f 1)=\"$(echo ${USB_CASPER} | cut -d= -f 2 | sed "s|\"||g")\"

###############################################################################
# Get the necessary functions in order to function correctly:
###############################################################################
INC_SRC=${MUK_DIR}/files/includes.sh
test -e ${INC_SRC} || INC_SRC=/usr/share/edit_chroot/includes.sh
if [[ ! -e ${INC_SRC} ]]; then echo Missing includes file!  Aborting!; exit 1; fi
source ${INC_SRC}
[[ $(ischroot; echo $?) -ne 1 ]] || systemctl daemon-reload

UI=$([[ "$1" =~ -ui$ ]] && echo "Y" || echo "N")
ACTION=${1/-ui/}
PARAMS=($@)
function _ui_title() { if [[ "$UI" == "N" ]]; then _title $@; else dialog --msgbox "$@" 8 60; clear; fi }
function _ui_error() { if [[ "$UI" == "N" ]]; then _error $@; else dialog --msgbox "$@" 8 60; clear; fi }

#==============================================================================
# If no help is requested, make sure needed packages have been installed:
#==============================================================================
if [[ ! "${ACTION}" =~ (help|--help) && "${ACTION}" != "debootstrap" && "$(dirname $0)" != "/usr/bin" ]]; then
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
				_title "Installing ${BLUE}${PKG}${NC} package..."
				apt install -y $PKG
			else
				_title "${BLUE}${PKG}${GREEN} package not available to install..."
			fi
		done
	fi
fi

#==============================================================================
# Function that safely unmount the chroot environment:
#==============================================================================
function ACTION_update()
{
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_ui_error "Cannot use ${BLUE}update${GREEN} inside chroot environment!"
		exit 1
	elif [[ ! -d ${MUK_DIR}/.git ]]; then
		_ui_error "Unable to update the toolkit because it is not a GitHub repository!"
		exit 1
	fi
	_title "Fetching latest version of this script"
	cd ${MUK_DIR}
	OWNER=($(ls -l | awk '{print $3":"$4}' | sort | uniq | grep -v "root:root" | grep -v "^:$"))
	git reset --hard
	git pull
	[[ ! -z "${OWNER[0]}" ]] && chown -R ${OWNER[0]} *
	[[ -f ${MUK_DIR}/install.sh ]] && ${MUK_DIR}/install.sh
	_ui_title "Script has been updated to latest version."
}

#==============================================================================
# Function that mount the unpacked CHROOT environment:
#==============================================================================
function ACTION_mount()
{
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
}

#==============================================================================
# Functions to change the unpacked CHROOT environment:
#==============================================================================
function ACTION_upgrade()
{
	ACTION_enter
}
function ACTION_build()
{
	ACTION_enter
}
function ACTION_sub_rollback()
{
	ACTION_enter
}
function ACTION_enter()
{
	#==========================================================================
	# Determine if we are working inside or outside the CHROOT environment
	#==========================================================================
	if [[ $(ischroot; echo $?) -eq 1 ]]; then
		#======================================================================
		# RESULT: We are outside the chroot environment:
		#======================================================================
		### First: Make sure that the CHROOT environment actually exists:
		cd ${UNPACK_DIR}
		if [[ "${ACTION}" != "debootstrap" ]]; then
			ACTION_unmount
			ACTION_mount || exit 1
		fi

		## Second: Are we building a particular combination of scripts we have?
		if [[ "${ACTION}" == "build" ]]; then
			option=$2
			valid=($(find ${MUK_DIR}/* -maxdepth 0 -type d | while read DIR; do basename $DIR; done | grep -v misc | grep -v files))
			if [[ -z "${valid[$option]}" ]]; then
				# If the "build" choice was made, ask which directory to run through:
				if [[ "${UI}" == "Y" ]]; then
					choice2=()
					for CHOICE in ${valid[@]}; do choice2+=(${CHOICE} ${CHOICE^}); done
					height=$(( ${#choice2[@]} / 2 + 7 ))
					option=$(dialog --menu "Available Builds:" ${height} 40 16  "${choice2[@]}" 2>&1 >/dev/tty)
					[[ -z "${option}" ]] && clear && exit
				else
					valid="${valid[@]}"
					valid=${valid// /${GREEN}, ${RED}}
					_error "Invalid build specified!  Supported values are: ${RED}${valid}${GREEN}!"
					exit 1
				fi
			fi
		fi

		### Third: Setup the CHROOT environment:
		cp /etc/resolv.conf ${UNPACK_DIR}/edit/etc/
		cp /etc/hosts ${UNPACK_DIR}/edit/etc/
		mount --bind /run/ ${UNPACK_DIR}/edit/run
		mount --bind /dev/ ${UNPACK_DIR}/edit/dev
		mount -t tmpfs tmpfs ${UNPACK_DIR}/edit/tmp
		mount -t tmpfs tmpfs ${UNPACK_DIR}/edit/var/cache/apt

		### Fourth: Copy the "edit_chroot" binary into the chroot environment:
		if [[ "$(dirname $0)" == "/usr/local/bin" ]]; then
			# Copy MUK into chroot environment
			rsync -a --delete ${MUK_DIR}/ ${UNPACK_DIR}/edit/${MUK_DIR}/
			chown root:root -R ${UNPACK_DIR}/edit/${MUK_DIR}
			chroot ${UNPACK_DIR}/edit ${MUK_DIR}/install.sh
		else
			# Extract the "edit-chroot" package into the CHROOT environment, since APT may not work at this point:
			cd ${UNPACK_DIR}/edit
			PKG=${PWD}/edit-chroot_$(rm edit-chroot_*_all.deb; apt download edit-chroot 2>&1 | grep -oe "[0-9]*\.[0-9]*\-[0-9]*")_all.deb
			dpkg-deb -x ${PKG} ${UNPACK_DIR}/edit
			FILE=${UNPACK_DIR}/edit/etc/apt/sources.list
			if grep "ubuntu" ${FILE}; then
				grep "universe" ${FILE} || sed -i "s|main restricted|main restricted universe multiverse|g" ${FILE}
			fi
		fi

		### Fifth: Enter the CHROOT environment:
		_title "Entering CHROOT environment"
		if [[ "${ACTION}" == "build" ]]; then
			chroot ${UNPACK_DIR}/edit edit_chroot build ${option}
		elif [[ "${ACTION}" == "debootstrap" ]]; then
			chroot ${UNPACK_DIR}/edit edit_chroot debootstrap ${DISTRO} ${ARCH}
		else
			chroot ${UNPACK_DIR}/edit edit_chroot ${PARAMS[@]}
		fi
		[[ -d ${UNPACK_DIR}/extract/live ]] && DIR=live || DIR=casper
		if [[ -f ${UNPACK_DIR}/edit/usr/local/finisher/build.txt ]]; then
			cp ${UNPACK_DIR}/edit/usr/local/finisher/build.txt ${UNPACK_DIR}/extract/${DIR}/build.txt
		else
			cp ${UNPACK_DIR}/edit/etc/os-release ${UNPACK_DIR}/extract/${DIR}/build.txt
		fi

		### Sixth: Run required commands outside chroot commands:
		if [[ -f ${UNPACK_DIR}/edit/usr/local/finisher/outside_chroot.list ]]; then
			ACTION_docker_mount
			_title "Executing scripts outside of CHROOT environment..."
			(while read p; do ${UNPACK_DIR}/edit/$p; done) < ${UNPACK_DIR}/edit/usr/local/finisher/outside_chroot.list
			ACTION_docker_umount
		fi

		### Seventh: Copy the new INITRD from the unpacked filesystem:
		cd ${UNPACK_DIR}/edit
		INITRD=$(ls initrd.img-* 2> /dev/null | tail -1)
		[[ -z "${INITRD}" ]] && INITRD=$(ls boot/initrd.img-* 2> /dev/null | tail -1)
		if [[ ! -z "${INITRD}" ]]; then
			# Is this Ubuntu?
			if [[ -d ${UNPACK_DIR}/extract/casper ]]; then
				_title "Moving ${BLUE}INITRD.IMG${GREEN} from unpacked filesystem from ${BLUE}${INITRD}${GREEN}..."
				mv ${UNPACK_DIR}/edit/${INITRD} ${UNPACK_DIR}/extract/casper/initrd
			# Or is this Debian?
			elif [[ -d ${UNPACK_DIR}/extract/live ]]; then
				_title "Moving ${BLUE}INITRD.IMG${GREEN} from unpacked filesystem from ${BLUE}${INITRD}${GREEN}..."
				mv ${UNPACK_DIR}/edit/${INITRD} ${UNPACK_DIR}/extract/live/initrd
			fi
		fi

		### Eighth: Rename "initrd.gz" entries only for Ubuntu (and maybe Debian):
		FILE=$(find ${UNPACK_DIR}/extract -name grub.cfg  -print -quit)
		[[ -z "${FILE}" ]] && sed -i "s|initrd.gz|initrd|g" ${FILE}

		### Ninth: Copy the new VMLINUZ from the unpacked filesystem:
		VMLINUZ=$(ls vmlinuz-* 2> /dev/null | tail -1)
		[[ -z "${VMLINUZ}" ]] && VMLINUZ=$(ls boot/vmlinuz-* 2> /dev/null | tail -1)
		if [[ ! -z "${VMLINUZ}" ]]; then
			# Is this Ubuntu?
			if [[ -d ${UNPACK_DIR}/extract/casper ]]; then
				_title "Moving ${BLUE}VMLINUZ${GREEN} from unpacked filesystem from ${BLUE}${VMLINUZ}${GREEN}...."
				mv ${UNPACK_DIR}/edit/${VMLINUZ} ${UNPACK_DIR}/extract/casper/vmlinuz
			# Or is this Debian?
			elif [[ -d ${UNPACK_DIR}/extract/live ]]; then
				_title "Moving ${BLUE}VMLINUZ${GREEN} from unpacked filesystem from ${BLUE}${VMLINUZ}${GREEN}...."
				mv ${UNPACK_DIR}/edit/${VMLINUZ} ${UNPACK_DIR}/extract/live/vmlinuz
			fi
		fi

		### Tenth: Remove mounts for CHROOT environment:
		cd ${UNPACK_DIR}
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

		### Second: Build debootstrap environment to start with:
		#[[ "${ACTION}" == "debootstrap" ]] && ACTION=enter		## NOTE: Uncomment this line to skip installing all the packages...
		_title "Updating APT repositories..."
		apt update
		if [[ "${ACTION}" == "debootstrap" ]]; then
			### Install systemd packages:
			_title "Installing systemd packages..."
			apt install -y libterm-readline-gnu-perl systemd-sysv
		fi
		if [[ -f /edit-chroot_*_all.deb ]]; then
			apt install -y /edit-chroot_*_all.deb
			rm /edit-chroot_*_all.deb
		fi

		### Third: Configure machine-id and divert:
		dbus-uuidgen > /etc/machine-id
		ln -fs /etc/machine-id /var/lib/dbus/machine-id
		dpkg-divert --local --rename --add /sbin/initctl >& /dev/null
		ln -sf /bin/true /sbin/initctl

		### Fourth: Continue building debootstrap environment:
		### Source Instructions: https://mvallim.github.io/live-custom-ubuntu-from-scratch/
		source /etc/os-release
		[[ "${ACTION}" == "debootstrap" ]] && CHROOT_debootstrap

		### Fifth: Put snap version firefox on hold if it is installed!
		### <<--- FYI --->> Snap packages CANNOT be updated inside the chroot environment!
		apt-mark hold firefox=*snap* 2> /dev/null > /dev/null
		test -e /usr/local/bin/cls || ln -sf /usr/bin/clear /usr/local/bin/cls

		### Sixth: Next action depends on parameter passed....
		if [[ "${ACTION}" =~ (enter|debootstrap) ]]; then
			### "enter": Create a bash shell for user to make alterations to chroot environment
			clear
			_title "Ready to modify CHROOT environment!"
			echo -e "${RED}NOTE: ${GREEN}Enter ${BLUE}exit${GREEN} to exit the CHROOT environment"
			echo -e ""
			echo "CHROOT" > /etc/debian_chroot
			echo ". ${INC_SRC}" >> /etc/skel/.bashrc
			bash -s
			sed -i "/${INC_SRC//\//\\\/}/d" /etc/skel/.bashrc
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

		### Seventh: Finish the debootstrap procedure:

		### Eighth: If user 999 exists, change that user ID so that LiveCD works:
		uid_name=$(grep ":999:" /etc/passwd | cut -d":" -f 1)
		if [[ ! -z "${uid_name}"  ]]; then
			uid_new=998
			while [ "$(id -u ${uid_new} >& /dev/null; echo $?)" -eq 0 ]; do uid_new=$((uid_new-1)); done
			_title "Changing user \"${uid_name}\" from UID 999 to ${uid_new} so LiveCD works..."
			usermod -u ${uid_new} ${uid_name}
			chown -Rhc --from=999 ${uid_new} / >& /dev/null
		fi

		### Ninth: If group 999 exists, change that group ID so that LiveCD works:
		gid_line=$(getent group 999)
		if [[ ! -z "${gid_line}" ]]; then
			gid_name=$(echo $gid_line | cut -d":" -f 1)
			gid_new=998
			while [ "$(getent group ${gid_new} >& /dev/null; echo $?)" -eq 0 ]; do gid_new=$((gid_new-1)); done
			_title "Changing group \"${gid_name}\" from GID 999 to ${gid_new} so LiveCD works..."
			groupmod -g ${gid_new} ${gid_name}
			chown -Rhc --from=:999 :${gid_new} / >& /dev/null
		fi

		### Tenth: Upgrade the installed GitHub repositories:
		if whereis git | grep -q "/git"; then
			_title "Updating GitHub repositories in ${BLUE}/opt${GREEN}..."
			cd /opt
		 	(ls | while read p; do pushd $p; [ -d .git ] && git pull; popd; done) >& /dev/null
		fi

		### Eleventh: Upgrade the pre-installed Kodi addons via GitHub repositories:
		if [ -d /opt/kodi ]; then
			_title "Updating Kodi addons from GitHub repositories in ${BLUE}/opt/kodi${GREEN}...."
			pushd /opt/kodi >& /dev/null
			(ls | while read p; do pushd $p; [ -d .git ] && git pull; popd; done) >& /dev/null
			popd >& /dev/null
		fi

		### Twelveth: Update packages:
		_title "Updating repository lists...."
		apt update >& /dev/null
		_title "Upgrading any packages requiring upgrading..."
		apt upgrade -y

		### Thirteenth: Purge older kernels from the image:
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
		apt install -f --autoremove --purge -y

		### Fifteenth: Remove any unnecessary packages:
		_title "Cleaning up cached packages..."
		apt autoclean -y >& /dev/null
		apt clean -y >& /dev/null

		### Sixteenth: Disable services not required during Live ISO:
		if [[ -f /usr/local/finisher/disabled.list ]]; then
			_title "Disabling unnecessary services for Live CD..."
			(while read p r; do systemctl disable $p; done) < /usr/local/finisher/disabled.list >& /dev/null
		fi

		### Seventeenth: Clean up everything done to "chroot" into this ISO image:
		_title "Undoing CHROOT environment modifications..."
		apt-mark unhold firefox=*snap* 2> /dev/null > /dev/null
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
}

#==============================================================================
# Functions to debootstrap an Debian/Ubuntu installation:
#==============================================================================
function ACTION_debootstrap()
{
	if [[ $(ischroot; echo $?) -eq 1 ]]; then
		### Remove unpacked ISO image:
		_title "Removing unpacked ISO image..."
		mount | grep -q "${UNPACK_DIR}/edit/image" && umount -lqf ${UNPACK_DIR}/edit/image
		mount | grep -q "${UNPACK_DIR}/edit" && umount -lqf ${UNPACK_DIR}/edit
		test -d ${UNPACK_DIR}/extract && rm -rf ${UNPACK_DIR}/extract
		mkdir ${UNPACK_DIR}/extract
		chown -R ${SUDO_USER}:${SUDO_USER} ${UNPACK_DIR}/extract 

		### Remove current chroot environment, because we are going to start over again:
		ACTION_remove || exit 1
		test -d ${UNPACK_DIR}/edit && rm -rf ${UNPACK_DIR}/edit 2> /dev/null
		mkdir -p ${UNPACK_DIR}/{edit,.upper}
		mount --bind ${UNPACK_DIR}/.upper ${UNPACK_DIR}/edit

		### Create the chroot environment by debootstrapping it!  Install "debootstrap" if not already installed!
		_title "Building debootstrapped chroot environment..."
		whereis debootstrap | grep -q "/debootstrap" || apt install -y debootstrap
		DISTRO=${2}
		[[ -z "${DISTRO}" ]] && DISTRO=$(grep UBUNTU_CODENAME= /etc/os-release | cut -d= -f 2)
		CUR_ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')
		ARCH=${3:-"${CUR_ARCH}"}
		debootstrap --arch=${ARCH} ${DISTRO:-"${VERSION_CODENAME}"} ${UNPACK_DIR}/edit || exit 1

		### Set the APT repositories:
		source ${UNPACK_DIR}/edit/etc/os-release
		echo "${NAME}-fs-live" > ${UNPACK_DIR}/edit/etc/hostname
		if [[ "${ID}" == "ubuntu" ]]; then
			(
				echo "deb http://ubuntu.securedservers.com/ ${VERSION_CODENAME} main restricted universe multiverse"
				echo "deb-src http://ubuntu.securedservers.com/ ${VERSION_CODENAME} main restricted universe multiverse"
				echo ""
				echo "deb http://ubuntu.securedservers.com/ ${VERSION_CODENAME}-security main restricted universe multiverse"
				echo "deb-src http://ubuntu.securedservers.com/ ${VERSION_CODENAME}-security main restricted universe multiverse"
				echo ""
				echo "deb http://ubuntu.securedservers.com/ ${VERSION_CODENAME}-updates main restricted universe multiverse"
				echo "deb-src http://ubuntu.securedservers.com/ ${VERSION_CODENAME}-updates main restricted universe multiverse"
				echo ""
				echo "deb http://ubuntu.securedservers.com/ ${VERSION_CODENAME}-backports main restricted universe multiverse"
				echo "deb-src http://ubuntu.securedservers.com/ ${VERSION_CODENAME}-backports main restricted universe multiverse"
			) > ${UNPACK_DIR}/edit/etc/apt/sources.list
		else
			(
				echo "deb http://ftp.de.debian.org/debian/ ${VERSION_CODENAME} main non-free non-free-firmware contrib"
				echo "deb-src http://ftp.de.debian.org/debian/ ${VERSION_CODENAME} main non-free non-free-firmware contrib"
				echo ""
				echo "deb http://ftp.de.debian.org/debian/ ${VERSION_CODENAME}-security main non-free non-free-firmware contrib"
				echo "deb-src http://ftp.de.debian.org/debian/ ${VERSION_CODENAME}-security main non-free non-free-firmware contrib"
				echo ""
				echo "deb http://ftp.de.debian.org/debian/ ${VERSION_CODENAME}-updates main non-free non-free-firmware contrib"
				echo "deb-src http://ftp.de.debian.org/debian/ ${VERSION_CODENAME}-updates main non-free non-free-firmware contrib"
				echo ""
				echo "deb http://ftp.de.debian.org/debian/ ${VERSION_CODENAME}-backports main non-free non-free-firmware contrib"
				echo "deb-src http://ftp.de.debian.org/debian/ ${VERSION_CODENAME}-backports main non-free non-free-firmware contrib"
			) > ${UNPACK_DIR}/edit/etc/apt/sources.list
		fi

		### Mount the now-empty ISO directory at "edit/image":
		mkdir -p ${UNPACK_DIR}/edit/image
		mount --bind ${UNPACK_DIR}/extract ${UNPACK_DIR}/edit/image
	fi

	### Enter the chroot environment we just created:
	ACTION_enter

	### If we are outside chroot, repack newly created chroot, then move files around properly:
	if [[ $(ischroot; echo $?) -eq 1 ]]; then
		ACTION_changes
		FILE=$(ls ${UNPACK_DIR}/extract/casper/filesystem-*.squashfs)
		mv ${FILE} ${UNPACK_DIR}/extract/casper/filesystem.squashfs
		mv ${FILE}.gpg ${UNPACK_DIR}/extract/casper/filesystem.squashfs.gpg
	fi
}
function CHROOT_debootstrap()
{
	### Upgrade packages first:
	_title "Upgrading packages..."
	apt upgrade -y

	### Install packages needed for Live System.  Note that certain packages may not be available on Debian!
	_title "Installing packages needed for Live System..."
	PKGS=($(apt list sudo ubuntu-standard casper discover laptop-detect os-prober network-manager net-tools \
			wireless-tools locales grub-common grub-gfxpayload-lists grub-pc grub-pc-bin grub2-common \
			efibootmgr initramfs-tools linux-firmware bash nano live-boot \
			ubiquity ubiquity-casper ubiquity-frontend-gtk ubiquity-slideshow-ubuntu ubiquity-ubuntu-artwork \
			grub-efi-amd64-signed shim-signed mtools binutils tasksel 2> /dev/null | grep "/" | cut -d/ -f 1))
	apt install -y ${PKGS[@]}

	### Install the kernel.  Note that package names differ between Ubuntu and Debian!
	_title "Installing the kernel..."
	apt install -y --no-install-recommends $([[ "${ID}" == "ubuntu" ]] && echo "linux-generic-hwe-${VERSION_ID}" || echo "linux-image-amd64")

	### Install pre-defined packages per user selection:
	sudo tasksel

	### Pre-configure locales.  Defaults to "en_US.UTF-8":
	sed -i "s|# ${LOCALE:-"en_US.UTF-8"}|${LOCALE:-"en_US.UTF-8"}|g" /etc/locale.gen
	locale-gen

	### Presets timezone.  Defaults to "America/Chicago":
	rm /etc/localtime
	ln -s /usr/share/zoneinfo/${TIMEZONE:-"America/Chicago"} /etc/localtime

	### Configure network-manager:
	(
		echo "[main]"
		echo "rc-manager=none"
		echo "plugins=ifupdown,keyfile"
		echo "dns=systemd-resolved"
		echo ""
		echo "[ifupdown]"
		echo "managed=false"
	) > /etc/NetworkManager/NetworkManager.conf
	dpkg-reconfigure network-manager

	### Start creating the "extract" folder for outside CHROOT:
	mkdir -p /image/{casper,isolinux,install}
	touch /image/ubuntu

	### Create our "grub.cfg" file:
	source /etc/os-release
	(
		echo "search --set=root --file /ubuntu"
		echo "insmod all_video"
		echo "set default=\"0\""
		echo "set timeout=30"
		echo ""
		echo "menuentry \"Try ${PRETTY_NAME} without installing\" {"
   		echo "	linux /casper/vmlinuz boot=casper nopersistent toram quiet splash ---"
   		echo "	initrd /casper/initrd"
		echo "}"
		echo ""
		echo "menuentry \"Install ${PRETTY_NAME}\" {"
   		echo "	linux /casper/vmlinuz boot=casper only-ubiquity quiet splash ---"
   		echo "	initrd /casper/initrd"
		echo "}"
		echo ""
		echo "menuentry \"Check disc for defects\" {"
   		echo "	linux /casper/vmlinuz boot=casper integrity-check quiet splash ---"
   		echo "	initrd /casper/initrd"
		echo "}"
		echo ""
		echo "grub_platform"
		echo "if [ \"\$grub_platform\" = \"efi\" ]; then"
		echo "	menuentry \"UEFI Firmware Settings\" {"
   		echo "		fwsetup"
		echo "	}"
		echo "	menuentry \"Test memory Memtest86+ (UEFI)\" {"
   		echo "		linux /install/memtest86+.efi"
		echo "	}"
		echo "else"
		echo "	menuentry \"Test memory Memtest86+ (BIOS)\" {"
   		echo "		linux16 /install/memtest86+.bin"
		echo "	}"
		echo "fi"
	) > /image/isolinux/grub.cfg

	### Create file /image/README.diskdefines:
	(
		echo "#define DISKNAME  ${PRETTY_NAME}"
		echo "#define TYPE  binary"
		echo "#define TYPEbinary  1"
		echo "#define ARCH  ${PARAM[1]}"
		echo "#define ARCHamd64  1"
		echo "#define DISKNUM  1"
		echo "#define DISKNUM1  1"
		echo "#define TOTALNUM  0"
		echo "#define TOTALNUM0  1"
	) > /image/README.diskdefines

	### Copy memtest86+ binary (BIOS and UEFI):
	_title "Retrieving memtest86+ for both BIOS and UEFI..."
	wget --progress=dot https://memtest.org/download/v7.00/mt86plus_7.00.binaries.zip -O /image/boot/memtest86.zip
	unzip -p /image/install/memtest86.zip memtest64.bin > /image/install/memtest86+.bin
	unzip -p /image/install/memtest86.zip memtest64.efi > /image/install/memtest86+.efi
	rm -f /image/boot/memtest86.zip

	### Create the EFI directory:
	_title "Building EFI directories, as well as UEFI boot image..."
	cd /image
	cp /usr/lib/shim/shimx64.efi.signed.previous /image/isolinux/bootx64.efi
	cp /usr/lib/shim/mmx64.efi /image/isolinux/mmx64.efi
	cp /usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed /image/isolinux/grubx64.efi

	### Create a FAT16 UEFI boot disk image containing the EFI bootloaders:
	(
		source /etc/os-release
		FILE=${NAME,,}-${VERSION_ID}_efi.img
		cd isolinux && \
		dd if=/dev/zero of=${FILE} bs=1K count=$(( $(du -BK -s ../EFI/boot | awk '{print $1}' | sed 's|K||') + 128 )) && \
		mkfs.vfat -F 16 ${FILE} && \
		LC_CTYPE=C mmd -i ${FILE} efi efi/ubuntu efi/boot && \
		LC_CTYPE=C mcopy -i ${FILE} ./bootx64.efi ::efi/boot/bootx64.efi && \
		LC_CTYPE=C mcopy -i ${FILE} ./mmx64.efi ::efi/boot/mmx64.efi && \
		LC_CTYPE=C mcopy -i ${FILE} ./grubx64.efi ::efi/boot/grubx64.efi && \
		LC_CTYPE=C mcopy -i ${FILE} ./grub.cfg ::efi/ubuntu/grub.cfg
	)

	### Create a grub BIOS image:
	grub-mkstandalone \
		--format=i386-pc \
		--output=isolinux/core.img \
		--install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
		--modules="linux16 linux normal iso9660 biosdisk search" \
		--locales="" \
		--fonts="" \
		"boot/grub/grub.cfg=isolinux/grub.cfg"
	cat /usr/lib/grub/i386-pc/cdboot.img isolinux/core.img > /image/boot/grub/i386-pc/eltorito.img

	## Unmount and remove the ISO image directory:
	umount /image
	rmdir /image
}

#==============================================================================
# Function that safely unmount the filesystem mount points:
#==============================================================================
function ACTION_unmount()
{
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_ui_error "Cannot use ${BLUE}unmount${GREEN} inside chroot environment!"
		exit 1
	fi
	_title "Unmounting filesystem mount points...."
	umount -qlf ${UNPACK_DIR}/edit/tmp/host >& /dev/null
	mount | grep "${UNPACK_DIR}/edit" | awk '{print $3}' | tac | while read DIR; do umount -qlf ${DIR}; done
	mount | grep "${UNPACK_DIR}/.lower" | awk '{print $3}' | while read DIR; do umount -qlf ${DIR} 2> /dev/null; test -d ${DIR} && rmdir ${DIR}; done
	ACTION_docker_umount -q
	_ui_title "All filesystem mount points should be unmounted now."
}

#==============================================================================
# Function that remove the unpacked filesystem:
#==============================================================================
function ACTION_remove()
{
	if [[ $(ischroot; echo $?) -ne 1 ]]; then
		_ui_error "Cannot use ${BLUE}remove${GREEN} inside chroot environment!"
		exit 1
	elif [[ ! -d ${UNPACK_DIR}/edit ]]; then
		return
	fi
	ACTION_unmount
	_title "Removing modifications to squashfs..."
	umount -q ${UNPACK_DIR}/edit
	test -d ${UNPACK_DIR}/.upper && rm -rf ${UNPACK_DIR}/.upper
	_ui_title "Modifications to squashfs filesystem has been removed."
}

#==============================================================================
# Function that unpack the ISO:
#==============================================================================
function ACTION_unpack()
{
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
	ACTION_remove
	_title "Copying contents of ISO..."
	mkdir -p extract
	rsync -a mnt/ extract

	# Third: Unmount the DVD/ISO if necessary:
	_title "Unmounting DVD/ISO from mount point...."
	umount -q mnt

	# Fourth: Tell user we done!
	_ui_title "Ubuntu ISO has been unpacked!"
}

#==============================================================================
# Function that pack the CHROOT environment:
#==============================================================================
function ACTION_changes()
{
	export SRC=.upper
	ACTION_unmount
	mkdir -p ${UNPACK_DIR}/edit
	mount --bind ${UNPACK_DIR}/.upper ${UNPACK_DIR}/edit || exit 1
	FUNC_pack
}
function ACTION_pack()
{
	export SRC=edit
	ACTION_unmount
	ACTION_mount || exit 1
	FUNC_pack
}
function FUNC_pack()
{
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
	[ -f ${UNPACK_DIR}/edit/etc/debian_chroot ] && rm ${UNPACK_DIR}/edit/etc/debian_chroot

	# Second: Call "FUNC_manifest" routine to build particular files required:
	FUNC_manifest

	# Third: Set necessary flags for compression:
	XZ=$([[ ${FLAG_XZ:-"0"} == "1" ]] && echo "-comp xz -Xdict-size 100%")

	# Fourth: Pack the filesystem into squashfs if required:
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
	ACTION_remove
	if [[ "${ACTION}" == "pack" || "${ACTION}" == "pack-xz" ]]; then
		mv ${UNPACK_DIR}/extract/${DIR}/${FS} ${UNPACK_DIR}/extract/${DIR}/filesystem.squashfs
		test -f ${UNPACK_DIR}/extract/${DIR}/${FS}.gpg && mv ${UNPACK_DIR}/extract/${DIR}/${FS}.gpg ${UNPACK_DIR}/extract/${DIR}/filesystem.squashfs.gpg
		rm ${UNPACK_DIR}/extract/${DIR}/filesystem_*.squashfs* 2> /dev/null
	fi

	# Seventh: Create MD5 checksum file:
	FUNC_md5sum

	# Eighth: Tell user we done!
	_ui_title "Done packing and preparing extracted filesystem!"
}

#==============================================================================
# Pack subroutine: Create manifest and filesystem size files:
#==============================================================================
function FUNC_manifest()
{
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
}

#==============================================================================
# Pack subroutine: Create md5 checksum file:
#==============================================================================
function FUNC_md5sum()
{
	_title "Creating the \"md5sum.txt\" file..."
	cd ${UNPACK_DIR}/extract
	[ -f md5sum.txt ] && rm md5sum.txt
	find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.txt >& /dev/null
}

#==============================================================================
# Function that create the ISO:
#==============================================================================
function ACTION_iso()
{
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
	ISO_FILE=${ID}-$(echo ${VERSION} | cut -d" " -f 1)-${MUK_BUILD:-"desktop-amd64"}
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
		FILE=${UNPACK_DIR}/${NAME}-${VERSION_ID}_efi.img
		if [[ ! -f ${FILE} ]]; then
			# Copy the files we need for the EFI partition to a temporary directory:
			EFI=/tmp/efi_tmp
			mkdir -p ${EFI}
			cp /usr/lib/shim/shimx64.efi.signed ${EFI}/bootx64.efi || exit 1
			cp /usr/lib/shim/mmx64.efi ${EFI}/mmx64.efi || exit 1
			cp /usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed ${EFI}/grubx64.efi || exit 1

			# Actually create our EFI partition:
			DIR=${UNPACK_DIR}/mnt
			truncate -s $(( $(du -BK -s ${EFI} | awk '{print $1}' | sed 's|K||') + 128 ))K ${FILE}
			mkfs.vfat ${FILE}
			mount ${FILE} ${DIR}
			mkdir -p ${DIR}/efi/boot
			cp -R ${EFI}/* ${DIR}/efi/boot/
			umount ${DIR}
			rm -rf ${EFI}
		fi

		# If necessary, create the hybrid MBR code file we need from the GRUB directory:
		FILE=${UNPACK_DIR}/${NAME}-${VERSION_ID}_hybrid.img
		if [[ ! -f ${FILE} ]]; then dd if=/usr/lib/grub/i386-pc/boot_hybrid.img of=${FILE} bs=1 count=432 || exit 1; fi

		# Figure out where the "eltorito.img" file is on the system:
		IMG=/boot/grub/i386-pc/eltorito.img
		if [[ ! -f ${UNPACK_DIR}/extract/${IMG} ]]; then
			IMG=/boot/grub/efi.img
			if [[ ! -f ${UNPACK_DIR}/extract/${IMG} ]]; then _ui_error "No Eltorito image file found!  Aborting!"; exit 1; fi
		fi

		# Finally pack up an ISO the new way:
		xorriso -as mkisofs -r \
  			-V "${PRETTY_NAME}" \
			-J -joliet-long -iso-level 3 \
  			-o ${ISO_DIR}/${ISO_FILE}.iso \
  			--grub2-mbr ${UNPACK_DIR}/${NAME}-${VERSION_ID}_hybrid.img \
  			-partition_offset 16 \
  			--mbr-force-bootable \
  			-append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b ${UNPACK_DIR}/${NAME}-${VERSION_ID}_efi.img \
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
}

#==============================================================================
# Function that rebuild the filesystem.squashfs and the ISO together:
#==============================================================================
function ACTION_rebuild()
{
	ACTION_pack && ACTION_iso
}
function ACTION_rebuild()
{
	FLAG_XZ=1
	ACTION_pack && ACTION_iso
}

#==============================================================================
# Function that mount chroot environment docker folder to host machine:
#==============================================================================
function ACTION_docker_mount()
{
	_title "Mounting chroot docker directory on live system:"

	# Create the necessary directories:
	[[ ! -d ${UNPACK_DIR}/edit/var/lib/docker ]] && mkdir -p ${UNPACK_DIR}/edit/var/lib/docker && chmod 722 ${UNPACK_DIR}/edit/var/lib/docker
	[[ ! -d /var/lib/docker ]] && mkdir -p /var/lib/docker

	# Stop docker, mount docker directory inside chroot environment, then start docker:
	systemctl stop docker
	mount --bind $UNPACK_DIR/edit/var/lib/docker /var/lib/docker
	systemctl start docker
}

#==============================================================================
# Function that unmount chroot environment docker folder from host machine?
#==============================================================================
function ACTION_docker_umount()
{
	# If the docker folder doesn't exist, exit the script:
	[[ ! -d ${UNPACK_DIR}/edit/var/lib/docker ]] && return

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
}

#==============================================================================
# Function that mount my Ubuntu split-partition USB stick properly:
#==============================================================================
function ACTION_usb_mount()
{
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
}

#==============================================================================
# Function that unmounts my Ubuntu split-partition USB stick properly:
#==============================================================================
function ACTION_usb_unmount()
{
	if mount | grep -q " ${UNPACK_DIR}/mnt "; then umount ${UNPACK_DIR}/mnt || exit 1; fi
	if mount | grep -q " ${UNPACK_DIR}/usb_efi "; then umount ${UNPACK_DIR}/usb_efi || exit 1; fi
	if mount | grep -q " ${UNPACK_DIR}/usb_casper "; then umount ${UNPACK_DIR}/usb_casper || exit 1; fi
	rmdir ${UNPACK_DIR}/usb_{efi,casper} 2> /dev/null
	_ui_title "Split-partition USB stick successfully unmounted!"
}

#==============================================================================
# Function to copy "extract" folder <<TO>> my Ubuntu split-partition USB stick:
#==============================================================================
function ACTION_usb_load()
{
	DEV=$(mount | grep "${UNPACK_DIR}/usb_casper" | cut -d" " -f 1)
	if [[ -z "${DEV}" ]]; then ACTION_usb_mount || exit 1; fi
	cp -R --verbose --update ${UNPACK_DIR}/extract/casper* ${UNPACK_DIR}/mnt/casper/
	eval `blkid -o export ${DEV}`
	FILE=$(find ${UNPACK_DIR}/mnt -name grub.cfg  -print -quit)
	sed -i "s| boot=casper||" ${FILE}
	sed -i "s| live-media=/dev/disk/by-uuid/[0-9a-z\-]*||" ${FILE}
	sed -i "s|vmlinuz |vmlinuz boot=casper live-media=/dev/disk/by-uuid/${UUID} |" ${FILE}
	_ui_title "File copy to split-partition USB stick completed!"
}

#==============================================================================
# Function that copy <<FROM>> my Ubuntu split-partition USB stick to "extract" folder:
#==============================================================================
function ACTION_usb_copy()
{
	DEV=$(mount | grep "${UNPACK_DIR}/usb_casper" | cut -d" " -f 1)
	if [[ -z "${DEV}" ]]; then ACTION_usb_mount || exit 1; fi
	cp -R --verbose --update ${UNPACK_DIR}/mnt/casper* ${UNPACK_DIR}/extract/casper
	FILE=$(find ${UNPACK_DIR}/extract -name grub.cfg  -print -quit)
	sed -i "s| live-media=/dev/disk/by-uuid/[0-9a-z\-]*||g" ${FILE}
	_ui_title "File copy from split-partition USB stick completed!"
}

#==============================================================================
# Function that updates snap configuration in the CHROOT environment:
#==============================================================================
function ACTION_snap()
{
	ACTION_unmount
	ACTION_mount || exit 1

	_title "Disabling current snaps...."
	SNAPS=($(snap list --all 2> /dev/null | grep -ve "disabled$" | awk '{print $1}' | sed "/^Name$/d"))
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
}

#==============================================================================
# Function that reverts chroot environment back one squashfs package:
# NOTE: Requires multiple squashfs files in the "casper" directory!
#==============================================================================
function ACTION_rollback()
{
	LAST=$(ls -r ${UNPACK_DIR}/extract/casper/filesystem_* | head -1)
	if [[ -z "${LAST}" ]]; then _ui_error "No squashfs files starting with ${BLUE}filesystem_${GREEN} found!  Aborting!"; exit 1; fi
	if [[ "$2" != "-y" && "$2" != "--yes" ]]; then
		dialog --stdout --title "Confirm Deletion" --defaultno --yesno "Delete $(basename ${FILE})?\n\nThis action cannot be undone!" 7 60 || exit 0
	fi

	# Remove filesystem changes, then get kernel files and generate initramfs:
	ACTION_remove
	ACTION_unmount
	rm ${LAST} || exit 1
	ACTION_sub_rollback
	FUNC_manifest
	FUNC_md5sum
	ACTION_remove
	_title "Rolled back ${BLUE}$(basename ${FILE})${GREEN} from chroot environment!"
}

###############################################################################
# Call requested function starting ACTION_, if it exists:
###############################################################################
[[ "${ACTION}" =~ -xz$ ]] && FLAG_XZ=1 && ACTION=${ACTION/-xz/}
if declare -F "ACTION_${ACTION}" > /dev/null; then
	ACTION_${ACTION} $@
	echo ""

###############################################################################
# Invalid parameter specified.  List available parameters:
###############################################################################
elif [[ ! -z "${ACTION}" || "${ACTION}" =~ (--|)help ]]; then
	[[ ! "${ACTION}" == "--help" ]] && echo "Invalid parameter specified!"
	echo "Usage: edit_chroot [OPTION]"
	echo ""
	echo "Available commands:"
	echo -e "  ${GREEN}unpack${NC}         Copies the Debian-based installer files from DVD or ISO on hard drive."
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

###############################################################################
# No command-line option specified!  Show the menu:
###############################################################################
else
	while true; do
		# Present the available options to the user.  Exit if no choice made:
		choices=(
			enter       "Enter the unpacked filesystem environment to make changes."
			unpack      "Copies the Debian-based installer files from DVD/ISO on hard drive"
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
		ACTION_${choice}-ui ${option2}
	done
	clear
fi
