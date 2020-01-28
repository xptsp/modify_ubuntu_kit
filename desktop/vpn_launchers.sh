#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs VPN browser launchers on your computer."
	echo -e "${RED}Dependency:${NC} VPN browser launchers requires FreeVPN to be established, plus Firefox and Google Chrome to be installed."
	echo ""
	exit 0
fi

# Make sure Firefox is installed:
#==============================================================================
PROG=$(whereis firefox | cut -d" " -f 2)
[[ -z "${PROG}" ]] && apt install -y firefox
PROG=$(whereis google-chrome | cut -d" " -f 2)
[[ -z "${PROG}" ]] && ${MUK_DIR}/desktop/chrome.sh

#==============================================================================
_title "Create VPN Browser launchers..."
#==============================================================================
# First: Create the sudoers policy to launch Firefox as user vpn without password:
#==============================================================================
cat << EOF > /etc/sudoers.d/vpn-browsers
User_Alias  X_USERS = kodi
Defaults:X_USERS env_reset
Defaults:X_USERS env_keep += DISPLAY 
Defaults:X_USERS env_keep += XAUTHORITY 

ALL ALL=(ALL) NOPASSWD:/usr/local/bin/firefox-vpn,/usr/local/bin/chrome-vpn
EOF
chmod 440 /etc/sudoers.d/vpn-browsers

# Second: Create the "firefox-vpn" script to launch Firefox as user vpn:
#==============================================================================
cat << EOF > /usr/local/bin/firefox-vpn
#!/bin/bash
# If we are not running as root, then run this script as root:
if [[ "\$EUID" -ne 0 ]]; then
        sudo \$0 \$@
        exit 0
fi

# Add user "htpc" to xhost, then launch firefox as user "htpc":
xhost +local:htpc
sudo -u htpc -H -- unshare firefox \$@ &
EOF
chmod +x /usr/local/bin/firefox-vpn

# Third: Create "chrome-vpn" script from "firefox-vpn" script:
#==============================================================================
cp /usr/local/bin/firefox-vpn /usr/local/bin/chrome-vpn
sed -i "s|firefox|google-chrome|g" /usr/local/bin/chrome-vpn

# Fourth: Create the launcher to launch Firefox as user htpc:
#==============================================================================
cp /usr/share/applications/firefox.desktop /usr/share/applications/firefox-vpn.desktop
sed -i "s|=firefox|=firefox-vpn|g" /usr/share/applications/firefox-vpn.desktop
sed -i "s|Icon=firefox-vpn|Icon=firefox|g" /usr/share/applications/firefox-vpn.desktop
sed -i "s|=Firefox Web|=Firefox VPN Web|g" /usr/share/applications/firefox-vpn.desktop
sed -i "s|Comment=Browse the World Wide Web|Comment=Browse the World Wide Web using the spiffy VPN\!|g" /usr/share/applications/firefox-vpn.desktop

# Fifth: Create the launcher to launch Google Chrome as user htpc:
#==============================================================================
cp /usr/share/applications/google-chrome.desktop /usr/share/applications/chrome-vpn.desktop
sed -i "s|=/usr/bin/google-chrome-stable|=/usr/local/bin/chrome-vpn|g" /usr/share/applications/chrome-vpn.desktop
sed -i "s|Name=Google Chrome|Name=Google Chrome VPN Web|g" /usr/share/applications/chrome-vpn.desktop
sed -i "s|Comment=Access the Internet|Comment=Access the Internet using the spiffy VPN\!|g" /usr/share/applications/chrome-vpn.desktop

