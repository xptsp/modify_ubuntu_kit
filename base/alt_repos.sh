#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Ubuntu alternate repos on your computer."
	echo -e "${RED}NOTE:${NC} Not needed on Ubuntu 22.04!"
	echo ""
	exit 0
fi

#==============================================================================
# First: Decide what OS paths to use:
#==============================================================================
CODE=$(cat /etc/os-release | grep "VERSION_CODENAME" | cut -d"=" -f 2)
VER=$(cat /etc/os-release | grep "VERSION=" | cut -d"\"" -f 2)
NAME=$(echo $VER | cut -d"(" -f 2 | cut -d")" -f 1)
VER=$(echo $VER | cut -d" " -f 1)

# Second: Write the replacement "sources.list" file:
#==============================================================================
#==============================================================================
_title "Update the ${RED}\"/etc/apt/sources.list\"${BLUE} file"
mv /etc/apt/sources.list /etc/apt/sources.list.backup
cat << EOF > /etc/apt/sources.list
# deb cdrom:[Xubuntu ${VER} LTS _${NAME}_ - Release amd64 / ${CODE} main multiverse restricted universe

# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://ubuntu.securedservers.com/ ${CODE} main restricted
# deb-src http://us.archive.ubuntu.com/ubuntu/ ${CODE} main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://ubuntu.securedservers.com/ ${CODE}-updates main restricted
# deb-src http://us.archive.ubuntu.com/ubuntu/ ${CODE}-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb http://ubuntu.securedservers.com/ ${CODE} universe
# deb-src http://us.archive.ubuntu.com/ubuntu/ ${CODE} universe
deb http://ubuntu.securedservers.com/ ${CODE}-updates universe
# deb-src http://us.archive.ubuntu.com/ubuntu/ ${CODE}-updates universe

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb http://ubuntu.securedservers.com/ ${CODE} multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ ${CODE} multiverse
deb http://ubuntu.securedservers.com/ ${CODE}-updates multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ ${CODE}-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb http://ubuntu.securedservers.com/ ${CODE}-backports main restricted universe multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ ${CODE}-backports main restricted universe multiverse

## Uncomment the following two lines to add software from Canonical's
## 'partner' repository.

## This software is not part of Ubuntu, but is offered by Canonical and the
## respective vendors as a service to Ubuntu users.
#deb http://archive.canonical.com/ubuntu ${CODE} partner
# deb-src http://archive.canonical.com/ubuntu ${CODE} partner

deb http://ubuntu.securedservers.com/ ${CODE}-security main restricted
# deb-src http://security.ubuntu.com/ubuntu ${CODE}-security main restricted
deb http://ubuntu.securedservers.com/ ${CODE}-security universe
# deb-src http://security.ubuntu.com/ubuntu ${CODE}-security universe
deb http://ubuntu.securedservers.com/ ${CODE}-security multiverse
# deb-src http://security.ubuntu.com/ubuntu ${CODE}-security multiverse
EOF
cp /etc/apt/sources.list /etc/apt/sources.list.new
apt update

# Third: Creating finisher task to replace generated repo list with our list:
#==============================================================================
add_taskd 10_sources.sh
