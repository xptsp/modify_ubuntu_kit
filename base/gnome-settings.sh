#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Sets custom Gnome settings."
	echo ""
	exit 0
fi

#==============================================================================
_title "Setting custom Gnome settings..."
#==============================================================================
mkdir -p  /etc/dconf/{profile,db/local.d}
[[ -f /etc/dconf/profile/user ]] || cat << EOF >  /etc/dconf/profile/user
user-db:user
system-db:local
EOF
STR="${EXTS[@]}"
cat << EOF >  /etc/dconf/db/local.d/00-reddragon-gnome-settings
[org/gnome/desktop/interface]
# Change time format to "AM/PM":
clock-format='12h'

# Set Dark mode for Appearances:
color-scheme='prefer-dark'
gtk-theme='Yaru-dark'

# Disable Automatic Screen Lock and Lock Screen on Suspend:
[org/gnome/desktop/screensaver]
lock-enabled=false
ubuntu-lock-on-suspend=false

# Set Dark mode for Appearances:
[org/gnome/gedit/preferences/editor]
scheme='Yaru-dark'

[org/gnome/settings-daemon/plugins/power]
# Enable automatic suspend after 30 minutes:
power-button-action='suspend'
sleep-inactive-ac-timeout=1800

# Pressing power button suspends computer:
sleep-inactive-ac-type='suspend'

[org/gnome/shell/extensions/dash-to-dock]
# Move Application Dock to bottom of screen:
dock-position='BOTTOM'

# Show Dock on all displays:
multi-monitor=true

# Hide Volumes and Devices on Application Dock:
show-mounts=false

# Hide Trash on Application Dock:
show-trash=false

# Change "Position of New Icons" to "Top Left":
[org/gnome/shell/extensions/ding]
start-corner='top-left'

# Set my "Favorite Applications" listed in the dock:
[org/gnome/shell]
favorite-apps=['firefox.desktop', 'thunderbird.desktop', 'org.gnome.Nautilus.desktop', 'rhythmbox.desktop', 'xfce4-terminal.desktop', 'gnome-control-center.desktop']

# Set Network Proxy to "automatic":
[org/gnome/system/proxy]
mode='auto'

[org/gtk/Settings/FileChooser]
# Set Dark mode for Appearances and clock to AM/PM format:
clock-format='12h'

# In Gnome Nautilus, sort Folders before Files:
sort-directories-first=true
EOF
dconf update
