#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs full Debian-based repos on your computer."
	echo ""
	exit 0
fi

#==============================================================================
# First: Write the replacement "sources.list" file:
#==============================================================================
_title "Updating the ${RED}\"/etc/apt/sources.list\"${BLUE} file"
source /etc/os-release
if [[ "${ID}" == "ubuntu" ]]; then
	(
		echo "deb http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME} main restricted universe multiverse"
		echo "deb-src http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME} main restricted universe multiverse"
		echo ""
		echo "deb http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME}-security main restricted universe multiverse"
		echo "deb-src http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME}-security main restricted universe multiverse"
		echo ""
		echo "deb http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME}-updates main restricted universe multiverse"
		echo "deb-src http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME}-updates main restricted universe multiverse"
		echo ""
		echo "deb http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME}-backports main restricted universe multiverse"
		echo "deb-src http://us.archive.ubuntu.com/ubuntu/ ${VERSION_CODENAME}-backports main restricted universe multiverse"
	) > /etc/apt/sources.list
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
	) > /etc/apt/sources.list
fi
apt update

# Second: Creating finisher task to replace generated repo list with our list:
#==============================================================================
add_taskd 10_sources.sh
