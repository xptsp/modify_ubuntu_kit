!/bin/bash
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

### Second: Alter docker-compose@mounts service to abort if volume not mounted:
#==============================================================================
<<<<<<< HEAD
mkdir /etc/systemd/system/docker-compose@mounts.service.d
cat << EOF > /etc/systemd/system/docker-compose@mounts.service.d/requires.conf
[Service]
ExecStartPre=/usr/bin/touch /mnt/Volume_1/.test
EOF
chattr +i /etc/systemd/system/docker-compose@mounts.service.d/requires.conf
[[ ! -d /mnt/Volume_1 ]] && mkdir -p /mnt/Volume_1
chmod -rwx -R /mnt/Volume_1
chattr +i -R /mnt/Volume_1

### Third: Create some helper scripts for docker-compose:
#==============================================================================
cat << EOF > /usr/local/bin/docker-always
#!/bin/bash
docker-compose -f /home/docker/always.yaml \$@
EOF
chmod +x /usr/local/bin/docker-always
cat << EOF > /usr/local/bin/docker-mounts
#!/bin/bash
touch /mnt/Volume_1/.test > /dev/null || (echo "[ERROR] Volume_1 mount point not writable!  Aborting!"; exit 1)
docker-compose -f /home/docker/mounts.yaml \$@
EOF
chmod +x /usr/local/bin/docker-mounts

### Fourth: Link to the docker-compose files for our services:
#==============================================================================
[[ ! -d /home/docker ]] && mkdir -p /home/docker
ln -sf ${MUK_DIR}/files/docker-always.yaml /home/docker/always.yaml
ln -sf ${MUK_DIR}/files/docker-mounts.yaml /home/docker/mounts.yaml

### Fifth: Add an "outside chroot environment" task for edit_chroot to run:
#==============================================================================
AO=$(ischroot && echo "add_outside")
${AO} ${MUK_DIR}/files/docker_outside.sh
=======
add_outside ${MUK_DIR}/files/docker_outside.sh
>>>>>>> parent of b63ed14... Okay, you got me....
