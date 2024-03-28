#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Yuzu on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Yuzu..."
#==============================================================================
# Download the AppImage and make executable:
FILE=/usr/bin/Linux-Yuzu-EA-4176.AppImage
wget https://github.com/pineappleEA/pineapple-src/releases/download/EA-4176/Linux-Yuzu-EA-4176.AppImage -O ${FILE}
chmod +x ${FILE}
cp ${MUK_DIR}/files/yuzu.png /usr/share/icons/

# Create application shortcut:
cat << EOF > /usr/share/applications/yuzu.desktop 
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=${FILE}
Name=Yuzu
Comment=Yuzu Nintendo Switch Emulator
Keywords=game;emulator;
Categories=Game;Emulator;
Icon=yuzu.png
EOF
