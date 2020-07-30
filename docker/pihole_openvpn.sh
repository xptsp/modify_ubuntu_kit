#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs PiHole and OpenVPN server."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installs PiHole and OpenVPN Server..."
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

### Second: Get everything we need for the services:
#==============================================================================
pushd /opt >& /dev/null
git clone https://github.com/mr-bolle/docker-openvpn-pihole
popd >& /dev/null
[[ ! -d /home/docker ]] && mkdir -p /home/docker
ln -sf /opt/docker-openvpn-pihole/docker-compose.yml /home/docker/pihole.yaml

### Third: Add an "outside chroot environment" task for edit_chroot to run:
#==============================================================================
if ischroot; then
	add_outside ${MUK_DIR}/files/docker_outside.sh
else
	${MUK_DIR}/files/docker_outside.sh
fi

### Fourth: Create a helper script for docker-compose:
#==============================================================================
cat << EOF > /usr/local/bin/docker-pihole
#!/bin/bash
docker-compose -f /home/docker/pihole.yaml \$@
EOF
chmod +x /usr/local/bin/docker-pihole
