#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Gnome extensions."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing packages for Gnome extensions..."
#==============================================================================
apt install -y gnome-shell-extensions chrome-gnome-shell 

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
_title "Installing some Gnome Extensions..."
#==============================================================================
mkdir /tmp/tmp
cd /tmp/tmp

# First extension: Grand Theft Focus >> https://extensions.gnome.org/extension/5410/grand-theft-focus/
wget https://extensions.gnome.org/extension-data/grand-theft-focuszalckos.github.com.v3.shell-extension.zip
gnome-extensions install grand-theft-focuszalckos.github.com.v3.shell-extension.zip
gnome-extensions enable grand-theft-focus@zalckos.github.com
rm grand-theft-focuszalckos.github.com.v3.shell-extension.zip

# Second extension: Burn My Windows >> https://extensions.gnome.org/extension/4679/burn-my-windows/
wget https://github.com/Schneegans/Burn-My-Windows/releases/latest/download/burn-my-windows@schneegans.github.com.zip
gnome-extensions install burn-my-windows@schneegans.github.com.zip
gnome-extensions enable burn-my-windows@schneegans.github.com
rm burn-my-windows@schneegans.github.com

# Third extension: Hibernate Status Button >> https://extensions.gnome.org/extension/755/hibernate-status-button/
wget https://extensions.gnome.org/extension-data/hibernate-statusdromi.v33.shell-extension.zip
gnome-extensions install hibernate-statusdromi.v33.shell-extension.zip
gnome-extensions enable hibernate-status@dromi
rm hibernate-statusdromi.v33.shell-extension.zip

# Fourth extension: Prevent Double Empty Window >> https://extensions.gnome.org/extension/4711/prevent-double-empty-window/
wget https://extensions.gnome.org/extension-data/prevent-double-empty-windowsilliewous.nl.v4.shell-extension.zip
gnome-extensions install prevent-double-empty-windowsilliewous.nl.v4.shell-extension.zip
gnome-extensions enable prevent-double-empty-window@silliewous.nl
rm prevent-double-empty-windowsilliewous.nl.v4.shell-extension.zip

# Fifth extension: Gnome Shell Volume Scroller >> https://github.com/francislavoie/gnome-shell-volume-scroller
wget https://extensions.gnome.org/extension-data/volume_scrollertrflynn89.pm.me.v7.shell-extension.zip
gnome-extensions install volume_scrollertrflynn89.pm.me.v7.shell-extension.zip
gnome-extensions enable volume_scroller@trflynn89.pm.me
rm volume_scrollertrflynn89.pm.me.v7.shell-extension.zip

# Fifth extension: OSD Volume Number >> https://extensions.gnome.org/extension/5461/osd-volume-number/
wget https://extensions.gnome.org/extension-data/osd-volume-numberdeminder.v6.shell-extension.zip
gnome-extensions install osd-volume-numberdeminder.v6.shell-extension.zip
gnome-extensions enable osd-volume-number@deminder
rm osd-volume-numberdeminder.v6.shell-extension.zip

# Sixth extension: OpenWeather >> https://extensions.gnome.org/extension/750/openweather/
wget https://extensions.gnome.org/extension-data/openweather-extensionjenslody.de.v107.shell-extension.zip
gnome-extensions install openweather-extensionjenslody.de.v107.shell-extension.zip
gnome-extensions enable openweather-extension@jenslody.de
rm openweather-extensionjenslody.de.v107.shell-extension.zip

# Seventh: Alphabetical Grid Extension >> https://extensions.gnome.org/extension/4269/alphabetical-app-grid/
wget https://extensions.gnome.org/extension-data/AlphabeticalAppGridstuarthayhurst.v32.shell-extension.zip
gnome-extensions install AlphabeticalAppGridstuarthayhurst.v32.shell-extension.zip
gnome-extensions enable AlphabeticalAppGrid@stuarthayhurst
rm AlphabeticalAppGridstuarthayhurst.v32.shell-extension.zip

# Eighth: No Activities Button >> https://extensions.gnome.org/extension/3184/no-activities-button/
wget https://extensions.gnome.org/extension-data/no_activitiesyaya.cout.v2.shell-extension.zip
gnome-extensions install no_activitiesyaya.cout.v2.shell-extension.zip
gnome-extensions enable no_activities@yaya.cout
rm no_activitiesyaya.cout.v2.shell-extension.zip

# Ninth: Applications Menu >> https://extensions.gnome.org/extension/6/applications-menu/
wget https://extensions.gnome.org/extension-data/apps-menugnome-shell-extensions.gcampax.github.com.v51.shell-extension.zip
gnome-extensions install apps-menugnome-shell-extensions.gcampax.github.com.v51.shell-extension.zip
gnome-extensions enable apps-menu@gnome-shell-extensions.gcampax.github.com
rm apps-menugnome-shell-extensions.gcampax.github.com.v51.shell-extension.zip
