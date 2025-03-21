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
_title "Installing compatible Gnome extensions..."
#==============================================================================
# Extensions to install:
#    1) Grand Theft Focus >> https://extensions.gnome.org/extension/5410/grand-theft-focus/
#    2) Dash-to-Dock Workaround >> https://extensions.gnome.org/extension/6712/dash-to-dock-workaround/
#    3) Prevent Double Empty Window >> https://extensions.gnome.org/extension/4711/prevent-double-empty-window/
#    4) OSD Volume Number >> https://extensions.gnome.org/extension/5461/osd-volume-number/
#    5) Refresh Wifi >> https://extensions.gnome.org/extension/905/refresh-wifi-connections/ 
#    6) GSConnect >> https://extensions.gnome.org/extension/1319/gsconnect/
#    7) OpenWeather >> https://extensions.gnome.org/extension/750/openweather/
#    8) Dock to Panel >> https://extensions.gnome.org/extension/1160/dash-to-panel/ 
#    9) ArcMenu >> https://extensions.gnome.org/extension/3628/arcmenu/ 
#   10) Reboot to UEFI >> https://extensions.gnome.org/extension/5105/reboottouefi/ 
#   11) GameMode >> https://extensions.gnome.org/extension/1852/gamemode/ 
#   12) Battery Indicator >> https://extensions.gnome.org/extension/5615/battery-indicator-upower/
#   13) Add To Desktop >> https://extensions.gnome.org/extension/3240/add-to-desktop/
#   14) Notification Banner Reloaded >> https://extensions.gnome.org/extension/4651/notification-banner-reloaded/ 
#   15) Sound Input & Output Device Chooser >> https://extensions.gnome.org/extension/906/sound-output-device-chooser/
#==============================================================================
add_package() { PKGS+=( $1 ); EXTS+=( $2 ); }
test -f /etc/apt/sources.list.d/xptsp_ppa.list || ${MUK_DIR}/base/custom-xptsp.sh
VER=$(apt list gnome-shell 2> /dev/null | grep -m 1 gnome | grep -m 1 -o -e '[0-9][0-9]\.' | cut -d. -f 1)
PKGS=()
EXTS=()
[[ "${VER}" -ge 40 && "${VER}" -le 44 ]] && add_package gnome-shell-extension-grand-theft-focus grand-theft-focus@zalckos.github.com
[[ "${VER}" -ge 42 && "${VER}" -le 44 ]] && add_package gnome-shell-extension-dash-to-dock-workaround dash-to-dock-workaround@popov895.ukr.net
[[ "${VER}" -ge 40 && "${VER}" -le 44 ]] && add_package gnome-shell-extension-prevent-double-empty-window prevent-double-empty-window@silliewous.nl
[[ "${VER}" -ge 42 && "${VER}" -le 44 ]] && add_package gnome-shell-extension-osd-volume-number osd-volume-number@deminder
[[ "${VER}" -ge 40 && "${VER}" -le 42 ]] && add_package gnome-shell-extension-refresh-wifi refresh-wifi@kgshank.net
[[ "${VER}" -eq 42 ]] && add_package gnome-shell-extension-openweather openweather-extension@jenslody.de
[[ "${VER}" -ge 42 && "${VER}" -le 44 ]] && add_package gnome-shell-extension-dash-to-panel dash-to-panel@jderose9.github.com
[[ "${VER}" -ge 42 && "${VER}" -le 44 ]] && add_package gnome-shell-extension-arcmenu arcmenu@arcmenu.com
[[ "${VER}" -ge 42 && "${VER}" -le 44 ]] && add_package gnome-shell-extension-reboot-to-uefi reboottouefi@ubaygd.com
[[ "${VER}" -ge 40 && "${VER}" -le 42 ]] && add_package gnome-shell-extension-gamemode gamemode@christian.kellner.me
[[ "${VER}" -ge 42 && "${VER}" -le 43 ]] && add_package gnome-shell-extension-battery-indicator-upower battery-indicator@jgotti.org
[[ "${VER}" -ge 42 && "${VER}" -le 44 ]] && add_package gnome-shell-extension-add-to-desktop add-to-desktop@tommimon.github.com
[[ "${VER}" -ge 40 && "${VER}" -le 44 ]] && add_package gnome-shell-extension-notification-banner-reloaded notification-banner-reloaded@marcinjakubowski.github.com
[[ "${VER}" -ge 40 && "${VER}" -le 42 ]] && add_package gnome-shell-extension-sound-output-device-chooser sound-output-device-chooser@kgshank.net
apt install -y ${PKGS[@]}    

#==============================================================================
_title "Enabling the installed gnome settings..."
#==============================================================================
mkdir -p  /etc/dconf/{profile,db/local.d}
[[ -f /etc/dconf/profile/user ]] || cat << EOF >  /etc/dconf/profile/user
user-db:user
system-db:local
EOF
STR="${EXTS[@]}"
cat << EOF >  /etc/dconf/db/local.d/00-reddragon-gnome-extensions
# List all extensions that you want to have enabled for all users
[org/gnome/shell]
enabled-extensions=['ding@rastersoft.com','ubuntu-appindicators@ubuntu.com','ubuntu-dock@ubuntu.com','${STR// /\',\'}']
EOF
dconf update

#==============================================================================
_title "Extracting and compiling custom schema files for extensions..."
#==============================================================================
cd /tmp/
unzip -o ${MUK_DIR}/files/gnome-extensions-schemas.zip
cd gnome-extensions-schemas/
ls | while read DIR; do
	DEST=/usr/share/gnome-shell/extensions/${DIR}/schemas
	if [[ -d "${DEST}" ]]; then
		XML=$(basename ${DIR}/*.xml)
		test -f ${DEST}/${XML}.original || cp ${DEST}/${XML} ${DEST}/${XML}.original
		mv ${DIR}/*.xml ${DEST}/
		glib-compile-schemas ${DEST}/
	fi
done
cd ..
rm -rf gnome-extensions-schemas/
