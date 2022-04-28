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
apt-get install -y ca-certificates curl gnupg lsb-release

#==============================================================================
_title "Installing Docker..."
#==============================================================================
FILE=/usr/share/keyrings/docker-archive-keyring.gpg
test -f ${FILE} && rm ${FILE}
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o ${FILE}
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt update
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
add_taskd 80_docker.sh

#==============================================================================
_title "Creating docker user..."
#==============================================================================
useradd -M -g docker -r -s /usr/sbin/nologin docker
[[ ! -d /home/docker ]] && mkdir -p /home/docker
