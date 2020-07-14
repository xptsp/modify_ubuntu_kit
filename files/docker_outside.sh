#!/bin/bash
[[ -f /usr/local/settings/finisher.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# Install docker on host system if not already installed:
[[ ! -f /usr/bin/docker ]] && ${MUK_DIR}/desktop/docker.sh

#==============================================================================
_title "Mounting cdroot docker directory on live system:"
#==============================================================================
# Create the necessary directories:
UNPACK_DIR=${UNPACK_DIR:-"/img"}
[[ ! -d ${UNPACK_DIR}/edit/home/docker/.sys ]] && mkdir -p ${UNPACK_DIR}/edit/home/docker/.sys
[[ ! -d /var/lib/docker ]] && mkdir -p /var/lib/docker

# Stop docker, mount docker directory inside chroot environment, then start docker:
systemctl stop docker
mount --bind $UNPACK_DIR/edit/home/docker/.sys /var/lib/docker
systemctl start docker

# Pull the images using docker-compose:
OLD_DIR=$(pwd)
cd ${UNPACK_DIR}/edit/home/docker
for file in *.yaml; do 
	_title "Pulling images specified in ${BLUE}${file}${GREEN}..."
	docker-compose -f $file pull; 
done
cd ${OLD_DIR}

#==============================================================================
_title "Unmounting cdroot docker directory from live system:"
#==============================================================================
systemctl stop docker
umount /var/lib/docker
systemctl start docker
