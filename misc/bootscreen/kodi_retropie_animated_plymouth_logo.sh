#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs an animated Kodi plymouth theme on your computer."
	echo ""
	exit 0
fi

#==============================================================================
# Install OpenBox for Kodi:
#==============================================================================
### First: Compile the "kodi-openbox" package:
git clone --depth=1 https://github.com/solbero/plymouth-theme-kodi-animated-logo /tmp/plymouth-theme-kodi-animated-logo
cp /opt/modify_ubuntu_kit/files/kodi_text.png /tmp/plymouth-theme-kodi-animated-logo/plymouth-theme-kodi-animated-logo/usr/share/plymouth/themes/kodi-animated-logo/
pushd /tmp/plymouth-theme-kodi-animated-logo
./build.sh
dpkg -i plymouth-theme-kodi-animated-logo.deb
popd
rm -rf /tmp/kodi-openbox
