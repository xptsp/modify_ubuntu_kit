#!/bin/bash
[[ -f /usr/local/settings/finisher.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

[[ "$1" == "pull" ]] && _title "Pulling ${BLUE}${2}${GREEN}..."
[[ "$1" == "tag" ]] && _title "Tagging ${BLUE}${2}${GREEN} as ${BLUE}${3}${GREEN}..."
/usr/bin/docker $@
