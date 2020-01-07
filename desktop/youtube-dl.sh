#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs YouTube-DL and YouTube-DL GUI on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install YouTube Downloader..."
#==============================================================================
wget https://yt-dl.org/latest/youtube-dl -O /usr/bin/youtube-dl
chmod +x /usr/bin/youtube-dl

#==============================================================================
_title "Install YouTube Downloader GUI..."
#==============================================================================
add-apt-repository -y ppa:nilarimogard/webupd8
apt install -y youtube-dlg

