#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Adds task to pull necessary Docker images for inclusion in Live CD."
	echo ""
	exit 0
fi

#==============================================================================
_title "Setting up to pull necessary Docker images for inclusion in Live CD..."
#==============================================================================
### First: Create the service file to launch the services upon boot:
#==============================================================================
cat << EOF > /etc/systemd/system/docker-compose@.service
[Unit]
Description=Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/docker
ExecStart=/usr/local/bin/docker-compose -f %i.yaml up -d
ExecStop=/usr/local/bin/docker-compose -f %i.yaml stop
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
systemctl disable docker-compose@always

### Second: Link to the docker-compose files for our services:
#==============================================================================
[[ ! -d /home/docker ]] && mkdir -p /home/docker
ln -sf ${MUK_DIR}/files/docker-always.yaml /home/docker/always.yaml
ln -sf ${MUK_DIR}/files/docker-mounts.yaml /home/docker/mounts.yaml

### Third: Add an "outside chroot environment" task for edit_chroot to run:
#==============================================================================
add_outside ${MUK_DIR}/files/docker_outside.sh
