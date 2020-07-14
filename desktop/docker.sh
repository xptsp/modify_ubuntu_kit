#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Docker on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Docker..."
#==============================================================================
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update
apt install -y docker-ce
if ischroot; then
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/80_docker.sh /usr/local/finisher/tasks.d/80_docker.sh
else
	${MUK_DIR}/files/tasks.d/80_docker.sh
fi

#==============================================================================
_title "Installing Docker Compose..."
#==============================================================================
wget https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#==============================================================================
_title "Creating docker user..."
#==============================================================================
useradd -M -g docker -r -s /usr/sbin/nologin docker
