#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Strips XFCE and some system-level software from install."
	echo ""
	exit 0
fi

#==============================================================================
_title "Stripping XFCE and some system-level software from install....."
#==============================================================================
dpkg -l | grep .xfce. | awk '{print $2}' | xargs apt-get purge -V --auto-remove -yy
apt remove -y --purge --autoremove firefox* cups* printer-driver-* transmission* system-config-* mate-calc* gnome-software*