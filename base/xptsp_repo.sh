#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs XPtsp APT repository onto the computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install XPtsp APT repository..."
#==============================================================================
# First: Install the repo...
curl -SsL https://xptsp.github.io/ppa/KEY.gpg | apt-key add -
curl -SsL -o /etc/apt/sources.list.d/bpiwrt_repo.list https://xptsp.github.io/ppa/ppa.list
apt update
apt upgrade -y
