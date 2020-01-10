#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs LIRC on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing LIRC..."
#==============================================================================
# First: Add the xenial repo, install the package, then remove the repo:
#==============================================================================
if [[ $OS_VER -gt 1604 ]]; then
	echo "deb http://ca.archive.ubuntu.com/ubuntu/ xenial universe" > /etc/apt/sources.list.d/xenial.list
	apt update
	apt install -y lirc/xenial
	apt-mark hold lirc
	rm /etc/apt/sources.list.d/xenial.list
	apt update
else
	apt install lirc
fi

# Second: Add finisher task to configure "LIRC":
#==============================================================================
if [[ ! -z "${CHROOT}" ]]; then
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/50_lirc.sh /usr/local/finisher/tasks.d/50_lirc.sh
else
	${MUK_DIR}/files/tasks.d/50_lirc.sh
fi
