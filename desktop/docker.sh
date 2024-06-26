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
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose

#==============================================================================
_title "Creating docker user..."
#==============================================================================
useradd -M -g docker -r -d /home/docker -s /usr/sbin/nologin docker
add_taskd 80_docker.sh

#==============================================================================
_title "Creating docker-compose services..."
#==============================================================================
# Create: docker-compose.service file:
cat << EOF > /lib/systemd/system/docker-compose.service
[Unit]
Description=Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker-compose -f /home/docker/docker-compose.yaml up
ExecStop=/usr/bin/docker-compose stop
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
# Create: docker-compose@.service file:
cat << EOF > /lib/systemd/system/docker-compose@.service
[Unit]
Description=Docker Compose Service (\%i)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker-compose -f /home/docker/%i/docker-compose.yaml up
ExecStop=/usr/bin/docker-compose stop
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
