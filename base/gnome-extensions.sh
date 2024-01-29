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
apt install -y jq gnome-shell-extensions

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
# Make sure the directory for storing the user's shell extension exists.
mkdir -p ~/.local/share/gnome-shell/extensions/
# Extract JSON "uuid" variable value from "metadata.json" in the ZIP-file.
MY_EXT_UUID=\$(unzip -p \$1 metadata.json | jq -r '.uuid')
# Check that variable is set to a non-empty string
if [ -z "\${MY_EXT_UUID}" ]; then
	echo "[ERROR] Could not extract the UUID from metadata.json in the ZIP-file."
	exit 1
fi
# Extract the ZIP-file to a subdirectory with the same name as the "uuid".
unzip -q -o \$1 -d ~/.local/share/gnome-shell/extensions/\$MY_EXT_UUID
# Restart Gnome Shell to activate the Gnome Shell extension.
busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting…")' > /dev/null 2>&1
# All is good.
echo "Gnome Shell Extension installed in ~/.local/share/gnome-shell/extensions/\$MY_EXT_UUID/"
exit 0
EOF
chmod +x /usr/local/bin/gnome-ext-install
