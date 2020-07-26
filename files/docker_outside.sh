@@ -1,37 +0,0 @@
#!/bin/bash
[[ -f /usr/local/settings/finisher.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# Install docker on host system if not already installed:
[[ ! -f /usr/bin/docker ]] && ${MUK_DIR}/desktop/docker.sh

# Pull the images using docker-compose:
OLD_DIR=$(pwd)
cd ${UNPACK_DIR}/edit/home/docker
for file in *.yaml; do 
	_title "Pulling images specified in ${BLUE}${file}${GREEN}..."
	docker-compose -f $file pull
done
cd ${OLD_DIR}
