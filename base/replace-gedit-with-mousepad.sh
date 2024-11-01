#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Mousepad on your computer, replacing GEdit (if installed)."
	echo ""
	exit 0
fi

#==============================================================================
_title "Removing GEdit..."
#==============================================================================
apt purge -y gedit gnome-text-editor

#==============================================================================
_title "Installing Mousepad..."
#==============================================================================
apt install -y mousepad

#==============================================================================
_title "Configuring Mousepad..."
#==============================================================================
dbus-launch --exit-with-session gsettings set org.xfce.mousepad.preferences.view color-scheme 'cobalt'
dbus-launch --exit-with-session gsettings set org.xfce.mousepad.preferences.view show-line-numbers true
dbus-launch --exit-with-session gsettings set org.xfce.mousepad.preferences.view highlight-current-line true
dbus-launch --exit-with-session gsettings set org.xfce.mousepad.preferences.view match-braces true
dbus-launch --exit-with-session gsettings set org.xfce.mousepad.preferences.view auto-indent true
dbus-launch --exit-with-session gsettings set org.xfce.mousepad.preferences.view smart-backspace true
dbus-launch --exit-with-session gsettings set org.xfce.mousepad.preferences.file add-last-end-of-line true
dbus-launch --exit-with-session gsettings set org.xfce.mousepad.preferences.view smart-backspace true
dbus-launch --exit-with-session gsettings set org.xfce.mousepad.preferences.view smart-home-end 'before'
dbus-launch --exit-with-session gsettings set org.xfce.mousepad.preferences.window opening-mode 'window'
dbus-launch --exit-with-session gsettings set org.xfce.mousepad.preferences.view tab-width 4
