#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Adds hibernation support."
	echo ""
	exit 0
fi

#==============================================================================
_title "Adding polkit for Hibernation option..."
#==============================================================================
cat << EOF > /etc/polkit-1/localauthority/50-local.d/com.ubuntu.enable-hibernate.pkla
[Re-enable hibernate by default in upower]
Identity=unix-user:*
Action=org.freedesktop.upower.hibernate
ResultActive=yes

[Re-enable hibernate by default in logind]
Identity=unix-user:*
Action=org.freedesktop.login1.hibernate;org.freedesktop.login1.handle-hibernate-key;org.freedesktop.login1;org.freedesktop.login1.hibernate-multiple-sessions;org.freedesktop.login1.hibernate-ignore-inhibit
ResultActive=yes
EOF

#==============================================================================
_title "Adding Gnome extension for Hibernate Status Button...."
# Src: https://extensions.gnome.org/extension/755/hibernate-status-button/
#==============================================================================
wget https://extensions.gnome.org/extension-data/hibernate-statusdromi.v33.shell-extension.zip
gnome-extensions install hibernate-statusdromi.v33.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable hibernate-status@dromi
rm hibernate-statusdromi.v33.shell-extension.zip

#==============================================================================
_title "Adding script to add hibernation support...."
#==============================================================================
add_bootd 65_hibernation.sh
