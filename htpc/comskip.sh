#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Builds ComSkip and Comskipper on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Compiling Comskip 0.82 for Linux..."
#==============================================================================
apt install -y autoconf libtool git build-essential libargtable2-dev libavformat-dev libsdl1.2-dev
git clone git://github.com/erikkaashoek/Comskip /tmp/Comskip
pushd /tmp/Comskip
./autogen.sh
./configure
make
popd
rm -rf /tmp/Comskip

#==============================================================================
_title "Installing the Comskipper service..."
#==============================================================================
git clone --depth=1 https://github.com/Helly1206/comskipper /tmp/comskipper
pushd /tmp/comskipper
./configure
make
make install
popd
rm -rf /tmp/comskipper

#==============================================================================
# Creating Comskip finisher task:
#==============================================================================
if [[ ! -z "${CHROOT}" ]]; then
	systemctl disable hts-skipper
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/50_hts_skipper.sh /usr/local/finisher/tasks.d/50_hts_skipper.sh
else
	systemctl enable hts-skipper
	systemctl start hts-skipper
	${MUK_DIR}/files/tasks.d/50_hts_skipper.sh
fi
