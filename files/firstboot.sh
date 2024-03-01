#!/bin/bash
# Determine where the toolkit is installed:
[[ -e /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e "${MUK_DIR}" ]] && exit 0

# If we are running off a live CD/USB, >>EXIT NOW<<!!!
if mount | grep " / " | grep -q "/cow "; then echo "Running on Live CD/USB!  Aborting..."; exit 0; fi

# Execute any firstboot scripts in the "/usr/local/finisher/firstboot.d" directory:
[[ $(ls /usr/local/finisher/boot.d/*.sh | wc -l) -ne 0 ]] && ls /usr/local/finisher/boot.d/*.sh | while read FILE; do ${FILE}; rm ${FILE}; done

exit 0
