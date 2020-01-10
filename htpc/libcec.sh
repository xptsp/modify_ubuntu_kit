#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs LibCEC support software on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install LibCEC packages..."
#==============================================================================
# First: Install the dependencies...
#==============================================================================
add-apt-repository -y ppa:pulse-eight/libcec
apt install -y libcec

# Second: Add finisher task:
#==============================================================================
if [[ ! -z "${CHROOT}" ]]; then
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/60_libcec.sh /usr/local/finisher/tasks.d/60_libcec.sh
else
	${MUK_DIR}/files/tasks.d/60_libcec.sh
fi
