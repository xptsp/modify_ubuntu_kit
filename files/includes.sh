#!/bin/bash

# Functions for zip and 7z files:
function zip() {
	[[ -z "$(whereis zip | cut -d" " -f 2)" ]] && apt install -y unzip
	command zip $@
}
function unzip() {
	[[ -z "$(whereis unzip | cut -d" " -f 2)" ]] && apt install -y unzip
	command unzip $@
}
function 7z() {
	[[ -z "$(whereis 7z | cut -d" " -f 2)" ]] && apt install -y p7zip-full
	command 7z $@
}

# Functions indicating what the script is doing ATM:
function _title() {
	echo -e "${GREEN}[${BLUE}${CHECK}${GREEN}] $@${NC}"
}
function _error() {
	echo -e "${GREEN}[${RED}x${GREEN}] $@${NC}"
}

# Function modified to not update when new repositories are added:
function apt-add-repository() {
	[[ -z "$(whereis -b apt-add-repository | cut -d":" -f 2)" ]] && apt install -y software-properties-common python-software-properties
	command apt-add-repository $@
	[[ $OS_VER -le 1604 ]] && apt update
}

# Functions modified to disable/enable specified services for Live CD usage:
function systemctl() {
	command systemctl $@
	ACTION=$1
	shift
	[[ "${ACTION}" == "enable"  ]] && __remove_from disabled $@
	[[ "${ACTION}" == "disable" ]] && __insert_into disabled $@
}
function service() {
	command service $@
	[[ "$2" == "enable"  ]] && __remove_from disabled $1
	[[ "$2" == "disable" ]] && __insert_into disabled $1
}

# Functions performing file alternations:
function __remove_from() {
	FILE=$1
	shift
	[ ! -d /usr/local/finisher ] && mkdir -p /usr/local/finisher
	if [ -f /usr/local/finisher/${FILE}.list ]; then
		cat /usr/local/finisher/${FILE}.list | grep -v "$1 " > /tmp/${FILE}.list
		mv /tmp/${FILE}.list /usr/local/finisher/${FILE}.list
	fi
}
function __insert_into() {
	FILE=$1
	shift
	__remove_from ${FILE} $@
	echo -e "$@ " >> /usr/local/finisher/${FILE}.list
}
function change_ownership() {
	__insert_into ownership $@
}
function change_password() {
	__insert_into password $@
}
function change_username() {
	__insert_into username $@
}
function relocate_dir() {
	__insert_into relocate $@
}
function add_outside() {
	P="$(echo $@ | sed "s|\"||g")"
	del_outside "$P"
	echo "$P" >> /usr/local/finisher/outside_chroot.list
}
function del_outside() {
	P="$(echo $@ | sed "s|\"||g")"
	if [ -f /usr/local/finisher/outside_chroot.list ]; then
		cat /usr/local/finisher/outside_chroot.list | grep -v "$P" > /tmp/outside_chroot.list
		mv /tmp/outside_chroot.list /usr/local/finisher/outside_chroot.list
	fi
}
function add_taskd() {
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	if ischroot; then
		ln -sf ${MUK_DIR}/files/tasks.d/$1 /usr/local/finisher/tasks.d/$1
	else
		${MUK_DIR}/files/tasks.d/$1
	fi
}
function add_bootd() {
	[[ ! -d /usr/local/finisher/boot.d ]] && mkdir -p /usr/local/finisher/boot.d
	if ischroot; then
		ln -sf ${MUK_DIR}/files/boot.d/$1 /usr/local/finisher/boot.d/$1
	else
		${MUK_DIR}/files/boot.d/$1
	fi
}
function add_postd() {
	[[ ! -d /usr/local/finisher/post.d ]] && mkdir -p /usr/local/finisher/post.d
	if ischroot; then
		ln -sf ${MUK_DIR}/files/post.d/$1 /usr/local/finisher/post.d/$1
	else
		${MUK_DIR}/files/post.d/$1
	fi
}

# Functions enabling and disabling sleep/hibernate functions:
function sleep_allow() {
	systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
}
function sleep_disallow() {
	systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
}

# Define functions assisting in string modification:
function chr() {
	[ "$1" -lt 256 ] || return 1
	printf "\\$(printf '%03o' "$1")"
}
function ord() {
	LC_CTYPE=C printf '%d' "'$1"
}

# Function reporting whether we are in a chroot environment:
function _chroot() {
	[[ $(ischroot; echo $?) -ne 1 ]] && return 1
}

# Function that enables specified Kodi addons:
function kodi_enable() {
	[[ ! -f /etc/skel/.kodi/userdata/Database/Addons27.db ]] && ${MUK_DIR}/base/kodi_addon_db.sh
	sqlite3 ~/.kodi/userdata/Database/Addons27.db 'update installed set enabled=1 where addonid=="$1";'
}
function kodi_repo() {
	${MUK_DIR:-"/opt/modify_ubuntu_kit"}/files/kodi_repo.sh $@
}

# If we are not running as root, then run this script as root:
if [[ "$UID" -ne 0 ]]; then
	sudo $0 $@
	exit $?
fi

# Kodi directories and URL base:
KODI_ADD=/usr/skel/.kodi/addons
KODI_OPT=/opt/kodi
KODI_BASE=https://mirrors.kodi.tv/addons/leia/

# Defined directories:
USB=${UNPACK_DIR}/usb
MNT=${UNPACK_DIR}/mnt
PTN2=${UNPACK_DIR}/extract-base
PTN3=${UNPACK_DIR}/extract-desktop
PTN4=${UNPACK_DIR}/extract-htpc
EXT=${UNPACK_DIR}/extract
ORG=${UNPACK_DIR}/original

# Define stuff we need for this script:
export DEBIAN_FRONTEND=noninteractive
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'
CHECK="\xE2\x9C\x94"

# What version of the Ubuntu OS are we running?
OS_VER=$(cat /etc/os-release | grep "VERSION_ID" | cut -d"\"" -f 2 | sed "s|\.||g")
OS_NAME=$(cat /etc/os-release  | grep VERSION_CODENAME | cut -d"=" -f 2)

# Store any flags passed to the script for later processing:
for opt in "$@"; do
	opt=${opt//-/}
	key=$(echo $opt | cut -d"=" -f 1)
	var=$(echo $opt | cut -d"=" -f 2)
	declare -A "options[${key//-/}]=${var}"
done

_chroot && CHROOT="Y" || unset CHROOT
