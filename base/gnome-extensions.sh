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

# Second: Dash-to-Dock Workaround >> https://extensions.gnome.org/extension/6712/dash-to-dock-workaround/
wget https://extensions.gnome.org/extension-data/dash-to-dock-workaroundpopov895.ukr.net.v3.shell-extension.zip
gnome-extensions install dash-to-dock-workaroundpopov895.ukr.net.v3.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable dash-to-dock-workaround@popov895.ukr.net
rm dash-to-dock-workaroundpopov895.ukr.net.v3.shell-extension.zip

# Third: Prevent Double Empty Window >> https://extensions.gnome.org/extension/4711/prevent-double-empty-window/
wget https://extensions.gnome.org/extension-data/prevent-double-empty-windowsilliewous.nl.v4.shell-extension.zip
gnome-extensions install prevent-double-empty-windowsilliewous.nl.v4.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable prevent-double-empty-window@silliewous.nl
rm prevent-double-empty-windowsilliewous.nl.v4.shell-extension.zip

# Fourth: OSD Volume Number >> https://extensions.gnome.org/extension/5461/osd-volume-number/
wget https://extensions.gnome.org/extension-data/osd-volume-numberdeminder.v6.shell-extension.zip
gnome-extensions install osd-volume-numberdeminder.v6.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable osd-volume-number@deminder
rm osd-volume-numberdeminder.v6.shell-extension.zip

# Fifth: Refresh Wifi >> https://extensions.gnome.org/extension/905/refresh-wifi-connections/ 
wget https://extensions.gnome.org/extension-data/refresh-wifikgshank.net.v16.shell-extension.zip
gnome-extensions install refresh-wifikgshank.net.v16.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable refresh-wifi@kgshank.net
rm refresh-wifikgshank.net.v16.shell-extension.zip

# Sixth: GSConnect >> https://extensions.gnome.org/extension/1319/gsconnect/
wget https://extensions.gnome.org/extension-data/gsconnectandyholmes.github.io.v50.shell-extension.zip
gnome-extensions install gsconnectandyholmes.github.io.v50.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable gsconnect@andyholmes.github.io
rm gsconnectandyholmes.github.io.v50.shell-extension.zip

# Seventh: OpenWeather >> https://extensions.gnome.org/extension/750/openweather/
wget https://extensions.gnome.org/extension-data/openweather-extensionjenslody.de.v118.shell-extension.zip
gnome-extensions install openweather-extensionjenslody.de.v118.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable openweather-extension@jenslody.de
rm openweather-extensionjenslody.de.v118.shell-extension.zip
unzip -o ${MUK_DIR}/files/openweather_schemas.zip -d ~/.local/share/gnome-shell/extensions/openweather-extension@jenslody.de/schemas/

# Eighth: Dock to Panel >> https://extensions.gnome.org/extension/1160/dash-to-panel/ 
wget https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v56.shell-extension.zip
gnome-extensions install dash-to-paneljderose9.github.com.v56.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable dash-to-panel@jderose9.github.com
rm dash-to-paneljderose9.github.com.v56.shell-extension.zip

# Ninth: ArcMenu >> https://extensions.gnome.org/extension/3628/arcmenu/ 
wget https://extensions.gnome.org/extension-data/arcmenuarcmenu.com.v48.shell-extension.zip
gnome-extensions install arcmenuarcmenu.com.v48.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable arcmenu@arcmenu.com
rm arcmenuarcmenu.com.v48.shell-extension.zip
