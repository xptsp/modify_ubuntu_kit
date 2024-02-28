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
_title "Installing Gnome Extensions manager GUI..."
#==============================================================================
apt install -y gnome-shell-extensions 

#==============================================================================
_title "Installing some Gnome Extensions globally..."
#==============================================================================
mkdir /tmp/tmp
cd /tmp/tmp

# First: Grand Theft Focus >> https://extensions.gnome.org/extension/5410/grand-theft-focus/
wget https://extensions.gnome.org/extension-data/grand-theft-focuszalckos.github.com.v3.shell-extension.zip
gnome-extensions install grand-theft-focuszalckos.github.com.v3.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable grand-theft-focus@zalckos.github.com
rm grand-theft-focuszalckos.github.com.v3.shell-extension.zip

# Second: Burn My Windows >> https://extensions.gnome.org/extension/4679/burn-my-windows/
wget https://extensions.gnome.org/extension-data/burn-my-windowsschneegans.github.com.v40.shell-extension.zip
gnome-extensions install burn-my-windowsschneegans.github.com.v40.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable burn-my-windows@schneegans.github.com
rm burn-my-windowsschneegans.github.com.v40.shell-extension.zip

# Third: Prevent Double Empty Window >> https://extensions.gnome.org/extension/4711/prevent-double-empty-window/
wget https://extensions.gnome.org/extension-data/prevent-double-empty-windowsilliewous.nl.v4.shell-extension.zip
gnome-extensions install prevent-double-empty-windowsilliewous.nl.v4.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable prevent-double-empty-window@silliewous.nl
rm prevent-double-empty-windowsilliewous.nl.v4.shell-extension.zip

# Fourth: Gnome Shell Volume Scroller >> https://github.com/francislavoie/gnome-shell-volume-scroller
wget https://extensions.gnome.org/extension-data/volume_scrollertrflynn89.pm.me.v7.shell-extension.zip
gnome-extensions install volume_scrollertrflynn89.pm.me.v7.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable volume_scroller@trflynn89.pm.me
rm volume_scrollertrflynn89.pm.me.v7.shell-extension.zip

# Fifth: OSD Volume Number >> https://extensions.gnome.org/extension/5461/osd-volume-number/
wget https://extensions.gnome.org/extension-data/osd-volume-numberdeminder.v6.shell-extension.zip
gnome-extensions install osd-volume-numberdeminder.v6.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable osd-volume-number@deminder
rm osd-volume-numberdeminder.v6.shell-extension.zip

# Sixth: Alphabetical Grid Extension >> https://extensions.gnome.org/extension/4269/alphabetical-app-grid/
wget https://extensions.gnome.org/extension-data/AlphabeticalAppGridstuarthayhurst.v32.shell-extension.zip
gnome-extensions install AlphabeticalAppGridstuarthayhurst.v32.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable AlphabeticalAppGrid@stuarthayhurst
rm AlphabeticalAppGridstuarthayhurst.v32.shell-extension.zip

# Seventh: No Activities Button >> https://extensions.gnome.org/extension/3184/no-activities-button/
wget https://extensions.gnome.org/extension-data/no_activitiesyaya.cout.v2.shell-extension.zip
gnome-extensions install no_activitiesyaya.cout.v2.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable no_activities@yaya.cout
rm no_activitiesyaya.cout.v2.shell-extension.zip

# Eighth: Applications Menu >> https://extensions.gnome.org/extension/6/applications-menu/
wget https://extensions.gnome.org/extension-data/apps-menugnome-shell-extensions.gcampax.github.com.v51.shell-extension.zip
gnome-extensions install apps-menugnome-shell-extensions.gcampax.github.com.v51.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable apps-menu@gnome-shell-extensions.gcampax.github.com
rm apps-menugnome-shell-extensions.gcampax.github.com.v51.shell-extension.zip

# Ninth: Places Menu >> https://extensions.gnome.org/extension/8/places-status-indicator/
# >>> NOTE: Already integrated into the Ubuntu 22.04 ISO!  We are just enabling it... <<<
dbus-launch --exit-with-session gnome-extensions enable places-menu@gnome-shell-extensions.gcampax.github.com

# Tenth: OpenWeather >> https://extensions.gnome.org/extension/750/openweather/
wget https://extensions.gnome.org/extension-data/openweather-extensionjenslody.de.v118.shell-extension.zip
gnome-extensions install openweather-extensionjenslody.de.v118.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable openweather-extension@jenslody.de
rm openweather-extensionjenslody.de.v118.shell-extension.zip
unzip -o ${MUK_DIR}/files/openweather_schemas.zip -d ~/.local/share/gnome-shell/extensions/openweather-extension@jenslody.de

# Eleventh: Show Desktop Applet >> https://extensions.gnome.org/extension/4267/show-desktop-applet/ 
wget https://extensions.gnome.org/extension-data/show-desktop-appletvalent-in.v5.shell-extension.zip
gnome-extensions install show-desktop-appletvalent-in.v5.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable show-desktop-applet@valent-in
rm show-desktop-appletvalent-in.v5.shell-extension.zip

# Twelveth: Refresh Wifi >> https://extensions.gnome.org/extension/905/refresh-wifi-connections/ 
wget https://extensions.gnome.org/extension-data/refresh-wifikgshank.net.v16.shell-extension.zip
gnome-extensions install refresh-wifikgshank.net.v16.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable refresh-wifi@kgshank.net
rm refresh-wifikgshank.net.v16.shell-extension.zip

#==============================================================================
_title "Moving Gnome Extensions to global extension directory..."
#==============================================================================
mv ~/.local/share/gnome-shell/extensions/* /usr/share/gnome-shell/extensions/

#==============================================================================
_title "Installing GSConnect Gnome Extensions to per-user storage..."
# Src: https://extensions.gnome.org/extension/1319/gsconnect/
#==============================================================================
wget https://extensions.gnome.org/extension-data/gsconnectandyholmes.github.io.v50.shell-extension.zip
gnome-extensions install gsconnectandyholmes.github.io.v50.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable gsconnect@andyholmes.github.io
rm gsconnectandyholmes.github.io.v50.shell-extension.zip
