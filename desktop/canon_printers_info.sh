#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs a Canon Drivers Website launcher on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Adding repository for Canon printer drivers..."
#==============================================================================
add-apt-repository -y ppa:thierry-f/fork-michael-gruz

#==============================================================================
_title "Creating ${BLUE}\"Canon Drivers Website\"${GREEN} launcher..."
#==============================================================================
cat << EOF > /usr/share/applications/canon-drivers.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Canon Drivers Website
Comment=Directions on how to Install Canon Printer Drivers
Exec=firefox http://ubuntuhandbook.org/index.php/2018/10/canon-ij-printer-scangear-mp-drivers-ubuntu-18-04-18-10/
Categories=System;
Icon=printer
Path=
Terminal=false
StartupNotify=false
EOF
