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
_title "Adding task to pull Docker images outside chroot environment..."
#==============================================================================
[[ ! -d /home/docker/.sys ]] && mkdir -p /home/docker/.sys
wget https://gist.githubusercontent.com/xptsp/7472b786a478664e4e3dbbf4c4a481db/raw/1a891aa3706787fb7964853d336b9bd10f3fdf82/docker-compose.yaml -O /home/docker/docker-compose.yaml
add_outside ${MUK_DIR}/files/docker_outside.sh
