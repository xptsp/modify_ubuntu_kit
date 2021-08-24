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
_title "Installing Docker prerequisites..."
#==============================================================================
#apt install -y apt-transport-https ca-certificates curl software-properties-common

#==============================================================================
_title "Installing Docker..."
#==============================================================================
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo $OS_NAME; exit
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${OS_NAME} stable"
apt update
apt install -y docker-ce
add_taskd 80_docker.sh

#==============================================================================
_title "Installing Docker Compose..."
#==============================================================================
VER=1.29.2
FILE=https://github.com/docker/compose/releases/download/${VER}/docker-compose-Linux-x86_64
OUT=/usr/local/bin/docker-compose-${VER}
wget ${FILE} -O ${OUT}
ln -sf ${OUT} /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#==============================================================================
_title "Creating docker user..."
#==============================================================================
useradd -M -g docker -r -s /usr/sbin/nologin docker
[[ ! -d /home/docker ]] && mkdir -p /home/docker

