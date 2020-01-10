#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs TVHeadEnd on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing TVHeadend (port 9981) and power-management scripts"
#==============================================================================
# First: Install the software:
#==============================================================================
add-apt-repository -y ppa:mamarley/tvheadend-git-stable
echo "tvheadend tvheadend/admin_username string kodi" | debconf-set-selections
echo "tvheadend tvheadend/admin_password password xubuntu" | debconf-set-selections
apt install -y tvheadend
relocate_dir /home/hts

# Second: Create default login settings tasks:
#==============================================================================
[[ ! -d /usr/local/finisher/post.d ]] && mkdir -p /usr/local/finisher/post.d
ln -sf ${MUK_DIR}/files/tasks.d/50_tvh.sh /usr/local/finisher/post.d/50_tvh.sh
change_username /usr/local/finisher/post.d/50_tvh.sh
change_password /usr/local/finisher/post.d/50_tvh.sh

# Third: Create the power management script needed:
#==============================================================================
if [[ ! -z "${CHROOT}" ]]; then
	system disable tvheadend
	[ ! -d /etc/pm/sleep.d ] && mkdir -p /etc/pm/sleep.d
	ln -sf ${MUK_DIR}/files/tvh_check-recordings.sh /etc/pm/sleep.d/70_check-recordings
else
	system enable tvheadend
	system start tvheadend
	${MUK_DIR}/files/tvh_check-recordings.sh
fi

# Fourth: Install a mobile UI for TVHeadEnd:
#==============================================================================
git clone --depth=1 git://github.com/polini/TvheadendMobileUI /opt/TvheadendMobileUI
ln -sf /opt/TvheadendMobileUI/mobile/ /usr/share/tvheadend/src/webui/static/mobile
