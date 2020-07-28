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
### First: Link to the docker-compose files for our services:
#==============================================================================
[[ ! -d /home/docker ]] && mkdir -p /home/docker
ln -sf ${MUK_DIR}/files/docker-misc.yaml /home/docker/misc.yaml

### Second: Add an "outside chroot environment" task for edit_chroot to run:
#==============================================================================
add_outside ${MUK_DIR}/files/docker_outside.sh

### Third: Create a script to launch retropie within the container:
#==============================================================================
cat << EOF > /usr/local/bin/docker-retropie
#!/bin/bash
docker run -it --rm \\
    --name=retropie \\
    --privileged \\
    -e DISPLAY=unix:0 \\
    -v /tmp/.X11-unix:/tmp/.X11-unix \\
    -e PULSE_SERVER=unix:/run/user/1000/pulse/native \\
    -v /run/user/1000:/run/user/1000 \\
    -v /dev/input:/dev/input \\
    -v retropie_roms:/home/kodi/RetroPie/roms \\
    -v ~/.config/retropie/emulationstation/:/home/kodi/.emulationstation/ \\
    -v ~/.config/retropie/autoconfig/:/opt/retropie/configs/all/retroarch/autoconfig/ \\
    -v ~/.config/retropie/retroarch.cfg:/opt/retropie/configs/all/retroarch.cfg \\
    lasery/retropie run
EOF
chmod +x /usr/local/bin/docker-retropie
change_username /usr/local/bin/docker-retropie
