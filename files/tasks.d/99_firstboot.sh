#!/bin/bash
# Determine where the toolkit is installed:
[[ -e /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e "${MUK_DIR}" ]] && exit 0

# If we are running off a live CD/USB, >>EXIT NOW<<!!!
mount | grep -q "/cow " && exit 0 

# Execute any firstboot scripts in the "/usr/local/finisher/firstboot.d" directory:
ls /usr/local/finisher/firstboot.d/* | while read FILE; do ${FILE}; rm ${FILE}; done

exit 0
