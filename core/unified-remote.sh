#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Unified Remote on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install Unified Remote..."
#==============================================================================
# First: Download and install the software:
#==============================================================================
test -f /etc/apt/sources.list.d/xptsp_ppa.list || ${MUK_DIR}/base/custom-xptsp.sh
apt install -y urserver

# Second: Make a custom remote that works with Ubuntu:
#==============================================================================
cd /opt/urserver/remotes/Unified/Main/
tar xfvz ${MUK_DIR}/files/PiInput.tgz

# Third: Adding Unified Remote systemd service:
#==============================================================================
ln -sf ${MUK_DIR}/files/urserver.service /etc/systemd/system/urserver.service
systemctl enable urserver
ischroot || systemctl start urserver
