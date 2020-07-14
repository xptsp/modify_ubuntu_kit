#!/bin/bash
# Install docker on host system if not already installed:
[[ ! -f /usr/bin/docker ]] && ${MUK_DIR}/desktop/docker.sh

#==============================================================================
_title "Pulling Docker images for chroot environment..."
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
for file in *.yaml; do docker-compose -f $file pull; done
cd ${OLD_DIR}

# Stop docker, unmount docker directory inside chroot environment, then start docker:
systemctl stop docker
umount /var/lib/docker
systemctl start docker
