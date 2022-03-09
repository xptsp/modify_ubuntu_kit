#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs the Ubiquity Slideshow script on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Add Ubiquity preview slideshow script to the OS..."
#==============================================================================
wget https://bazaar.launchpad.net/~ubiquity-slideshow/ubiquity-slideshow-ubuntu/html/download/head:/slideshow.py-20090619151040-8jaidpfc7mggtrv9-1/Slideshow.py -O /usr/share/ubiquity-slideshow/slideshow.py
chmod +x /usr/share/ubiquity-slideshow/slideshow.py


