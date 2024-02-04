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
apt install -y jq gnome-shell-extensions gettext make

#==============================================================================
_title "Adding script to automate installing gnome extensions..."
# Src: https://www.pragmaticlinux.com/2021/06/manually-install-a-gnome-shell-extension-from-a-zip-file/
#==============================================================================
cat << EOF > /usr/local/bin/gnome-ext-install
#!/bin/bash
# Function to display usage information
display_usage() { 
	echo "Install a Gnome Shell Extension from a ZIP-file." 
	echo "Usage: gnome-ext-install <zip-file>" 
} 
# Verify that the first parameter is an existing file with the ".zip" extension
if [ ! -f \$1 ] || [ "\${1: -4}" != ".zip" ]; then
	display_usage
	echo "[ERROR] No existing ZIP-file specified as a parameter."
	exit 1
fi
# Make sure the "jq" tool is installed on the system.
if [ ! -x "\$(command -v jq)" ]; then
	echo "[ERROR] jq is not installed on your system. Install with:"
	echo "	* sudo apt install jq (Ubuntu/Debian)"
	echo "	* sudo dnf install jq (Fedora)"
	echo "	* sudo zypper install jq (openSUSE)"
	exit 1
fi

# If "-s" or "--system" is specified as 2nd parameter, store in global system extensions:
if [[ "$2" == "-s" || "$2" == "--system" ]]; then
	DIR=/usr/share/gnome-shell/extensions
	# If we are not running as root, then run this script as root:
	if [[ "$UID" -ne 0 ]]; then
		sudo $0 $@
		exit $?
	fi
else
	DIR=~/.local/share/gnome-shell/extensions/
fi
# Make sure the directory for storing the user's shell extension exists.
mkdir -p \${DIR} 
# Extract JSON "uuid" variable value from "metadata.json" in the ZIP-file.
MY_EXT_UUID=\$(unzip -p \$1 metadata.json | jq -r '.uuid')
# Check that variable is set to a non-empty string
if [ -z "\${MY_EXT_UUID}" ]; then
	echo "[ERROR] Could not extract the UUID from metadata.json in the ZIP-file."
	exit 1
fi
# Extract the ZIP-file to a subdirectory with the same name as the "uuid".
unzip -q -o \$1 -d \${DIR}\$MY_EXT_UUID
# Restart Gnome Shell to activate the Gnome Shell extension.
busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting…")' > /dev/null 2>&1
# All is good.
echo "Gnome Shell Extension installed in \${DIR}/\$MY_EXT_UUID/"
exit 0
EOF
chmod +x /usr/local/bin/gnome-ext-install

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
apt install -y chrome-gnome-shell
mkdir /tmp/tmp
cd /tmp/tmp

# First extension: Grand Theft Focus (https://github.com/zalckos/GrandTheftFocus):
wget https://github.com/zalckos/GrandTheftFocus/releases/download/v3/grand-theft-focuszalckos.github.com.v3.shell-extension.zip
gnome-ext-install grand-theft-focuszalckos.github.com.v3.shell-extension.zip
rm grand-theft-focuszalckos.github.com.v3.shell-extension.zip

# Second extension: OpenWeather (https://gitlab.com/skrewball/openweather.git):
git clone https://gitlab.com/skrewball/openweather.git
cd openweather
make && make install
cd ..
rm -rf openweather

# Third extension: OSD Volume Number (https://github.com/Deminder/osd-volume-number):
git clone https://github.com/Deminder/osd-volume-number
cd osd-volume-number
git submodule update --init --remote --recursive --checkout sdt
make install
cd ..
rm -rf osd-volume-number

# Forth extension: Prevent Double Empty Window (https://gitlab.com/g3786/prevent-double-empty-window)
git clone https://gitlab.com/g3786/prevent-double-empty-window.git
cd prevent-double-empty-window
zip ../prevent-double-empty-window.zip *
cd ..
gnome-ext-install prevent-double-empty-window.zip
rm -rf prevent-double-empty-window*
