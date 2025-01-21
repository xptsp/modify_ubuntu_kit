#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installing compatible Gnome extensions & manager."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Gnome Extensions manager GUI..."
#==============================================================================
apt install -y gnome-shell-extensions 

#==============================================================================
_title "Installing Compatible Gnome Extensions..."
#==============================================================================
# Extensions to install:
#    1) Grand Theft Focus >> https://extensions.gnome.org/extension/5410/grand-theft-focus/
#    2) Dash-to-Dock Workaround >> https://extensions.gnome.org/extension/6712/dash-to-dock-workaround/
#    3) Prevent Double Empty Window >> https://extensions.gnome.org/extension/4711/prevent-double-empty-window/
#    4) OSD Volume Number >> https://extensions.gnome.org/extension/5461/osd-volume-number/
#    5) Refresh Wifi >> https://extensions.gnome.org/extension/905/refresh-wifi-connections/ 
#    6) GSConnect >> https://extensions.gnome.org/extension/1319/gsconnect/
#==============================================================================
VER=$(apt list gnome-shell 2> /dev/null | grep -m 1 gnome | grep -m 1 -o -e '[0-9][0-9]\.' | cut -d. -f 1)
PKGS=()
[[ "${VER}" -eq 42 ]] && PKGS+=( gnome-shell-extension-gsconnect )
[[ "${VER}" -ge 40 && "${VER}" -le 44 ]] && PKGS+=( gnome-shell-extension-grand-theft-focus )
[[ "${VER}" -ge 42 && "${VER}" -le 44 ]] && PKGS+=( gnome-shell-extension-dash-to-dock-workaround )
[[ "${VER}" -ge 40 && "${VER}" -le 44 ]] && PKGS+=( gnome-shell-extension-prevent-double-empty-window )
[[ "${VER}" -ge 42 && "${VER}" -le 44 ]] && PKGS+=( gnome-shell-extension-osd-volume-number )
[[ "${VER}" -ge 40 && "${VER}" -le 42 ]] && PKGS+=( gnome-shell-extension-prevent-refresh-wifi )
apt install -y ${PKGS}    

#==============================================================================
_title "Installing some Gnome Extensions globally..."
#==============================================================================
mkdir /tmp/tmp
cd /tmp/tmp

# Seventh: OpenWeather >> https://extensions.gnome.org/extension/750/openweather/
wget https://extensions.gnome.org/extension-data/openweather-extensionjenslody.de.v118.shell-extension.zip
gnome-extensions install openweather-extensionjenslody.de.v118.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable openweather-extension@jenslody.de
rm openweather-extensionjenslody.de.v118.shell-extension.zip

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

# Tenth: Reboot to UEFI >> https://extensions.gnome.org/extension/5105/reboottouefi/ 
wget https://extensions.gnome.org/extension-data/reboottouefiubaygd.com.v14.shell-extension.zip
gnome-extensions install reboottouefiubaygd.com.v14.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable reboottouefi@ubaygd.com
rm reboottouefiubaygd.com.v14.shell-extension.zip

# Eleventh: GameMode >> https://extensions.gnome.org/extension/1852/gamemode/ 
wget https://extensions.gnome.org/extension-data/gamemodechristian.kellner.me.v7.shell-extension.zip
gnome-extensions install gamemodechristian.kellner.me.v7.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable gamemode@christian.kellner.me
rm gamemodechristian.kellner.me.v7.shell-extension.zip

# Twelfth: Battery Indicator >> https://extensions.gnome.org/extension/5615/battery-indicator-upower/ 
wget https://extensions.gnome.org/extension-data/battery-indicatorjgotti.org.v7.shell-extension.zip
gnome-extensions install battery-indicatorjgotti.org.v7.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable battery-indicator@jgotti.org
rm battery-indicatorjgotti.org.v7.shell-extension.zip

# Thirteenth: Add To Desktop >> https://extensions.gnome.org/extension/3240/add-to-desktop/
wget https://extensions.gnome.org/extension-data/add-to-desktoptommimon.github.com.v10.shell-extension.zip
gnome-extensions install add-to-desktoptommimon.github.com.v10.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable add-to-desktop@tommimon.github.com
rm add-to-desktoptommimon.github.com.v10.shell-extension.zip

# Fourteenth: Notification Banner Reloaded >> https://extensions.gnome.org/extension/4651/notification-banner-reloaded/ 
wget https://extensions.gnome.org/extension-data/notification-banner-reloadedmarcinjakubowski.github.com.v8.shell-extension.zip
gnome-extensions install notification-banner-reloadedmarcinjakubowski.github.com.v8.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable notification-banner-reloaded@marcinjakubowski.github.com
rm notification-banner-reloadedmarcinjakubowski.github.com.v8.shell-extension.zip

# Fifteenth: Sound Input & Output Device Chooser >> https://extensions.gnome.org/extension/906/sound-output-device-chooser/
wget https://extensions.gnome.org/extension-data/sound-output-device-chooserkgshank.net.v43.shell-extension.zip
gnome-extensions install sound-output-device-chooserkgshank.net.v43.shell-extension.zip
dbus-launch --exit-with-session gnome-extensions enable sound-output-device-chooser@kgshank.net
rm sound-output-device-chooserkgshank.net.v43.shell-extension.zip

#==============================================================================
_title "Extracting and compiling custom schema files for extensions..."
#==============================================================================
cd /tmp/
unzip -o ${MUK_DIR}/files/gnome-extensions-schemas.zip
cd gnome-extensions-schemas/
ls | while read DIR; do
	DEST=~/.local/share/gnome-shell/extensions/${DIR}/schemas
	XML=$(basename ${DIR}/*.xml)
	test -f ${DEST}/${XML}.original || cp ${DEST}/${XML} ${DEST}/${XML}.original
	mv ${DIR}/*.xml ${DEST}/
	glib-compile-schemas ${DEST}/
done
cd ..
rm -rf gnome-extensions-schemas/
