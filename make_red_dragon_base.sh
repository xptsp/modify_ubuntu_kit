#!/bin/bash
DST=/usr/local/bin
MUK=$(cd $(dirname $0); pwd)
BIN=${MUK}/red_dragon

# If we are not running as root, then run this script as root:
if [[ "$EUID" -ne 0 ]]; then
	sudo $0 $@
	exit 0
fi

# Install our tools to the destination folder:
for file in ${BIN}/*.sh; do . ${file}; done
apt dist-upgrade -y --autoremove