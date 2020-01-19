#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs SpyBot Search \& Destroy hosts file on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Adding finisher task to add these to the generated hosts file..."
#==============================================================================
# First: Install p7zip-full package if not already installed:
FILE=$(whereis 7z | cut -d" " -f 2)
[[ -z "${FILE}" ]] && apt install -y p7zip-full

# Second: Add/execute finisher task:
if ischroot; then
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/11_hosts.sh /usr/local/finisher/tasks.d/11_hosts.sh
else
	${MUK_DIR}/files/tasks.d/11_hosts.sh
fi