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
_title "Adding script to get changed Gnome settings..."
#==============================================================================
FILE=/usr/local/bin/gsettings-diff
cat << EOF > ${FILE}
#!/bin/sh
BEFORE=\`mktemp /tmp/gsettingsXXXXX\`
gsettings list-recursively > \$BEFORE
echo -n "Ok, recorded current settings - now do the change and press enter ..."
read ANS
AFTER=\`mktemp /tmp/gsettingsXXXXX\`
gsettings list-recursively > \$AFTER
diff -u \$BEFORE \$AFTER
rm \$BEFORE \$AFTER
EOF
chmod +x ${FILE}

#==============================================================================
_title "Setting custom Gnome settings..."
#==============================================================================
function gsettings() {
	dbus-launch --exit-with-session /usr/bin/gsettings $@ 2> /dev/null
}

# Enable automatic suspend after 30 minutes:
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 1800
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'

# Pressing power button suspends computer:
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'

# Set Dark mode for Appearances:
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
gsettings set org.gnome.gedit.preferences.editor scheme 'Yaru-dark'

# Move Application Dock to bottom of screen:
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'

# Hide Volumes and Devices on Application Dock:
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false

# Hide Trash on Application Dock:
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false

# Change "Position of New Icons" to "Top Left":
gsettings set org.gnome.shell.extensions.ding start-corner 'top-left'

# Change time format to "AM/PM":
gsettings set org.gnome.desktop.interface clock-format '12h'
gsettings set org.gtk.Settings.FileChooser clock-format '12h'

# Disable Automatic Screen Lock:
gsettings set org.gnome.desktop.screensaver lock-enabled false

# Disable Lock Screen on Suspend:
gsettings set org.gnome.desktop.screensaver ubuntu-lock-on-suspend false

# In Gnome Nautilus, sort Folders before Files:
gsettings set org.gtk.Settings.FileChooser sort-directories-first true

# Show Dock on all displays:
gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true

# Set Network Proxy to "automatic":
gsettings set org.gnome.system.proxy mode 'auto'

# Set my "Favorite Applications" listed in the dock:
gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'thunderbird.desktop', 'org.gnome.Nautilus.desktop', 'rhythmbox.desktop', 'xfce4-terminal.desktop', 'gnome-control-center.desktop']"
