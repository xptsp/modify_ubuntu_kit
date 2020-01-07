#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Kodi on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Kodi..."
#==============================================================================
### First: Install the software (duh):
#==============================================================================
apt-add-repository -y ppa:team-xbmc/ppa
apt install -y kodi kodi-pvr-iptvsimple kodi-pvr-hts kodi-visualization-[wgs]* kodi-peripheral-* kodi-screensaver-*

### Second: Download the default Kodi settings:
#==============================================================================
7z x ${MUK_DIR}/files/kodi_userdata.7z -aoa -o${HOME}/.kodi/userdata/

### Third: Download our modified "skin.estuary" files:
#==============================================================================
7z x ${MUK_DIR}/files/kodi_skin.estuary.zip -aoa -o/usr/share/kodi/addons/

### Fourth: Download Harmony Remote keymap and adjust the keymap a little:
### Original Source: https://forum.kodi.tv/showthread.php?tid=188542
#==============================================================================
[[ ! -d ${HOME}/.kodi/userdata/keymaps ]] && mkdir ${HOME}/.kodi/userdata/keymaps
ln -sf ${MUK_DIR}/files/harmony_remote.xml ${HOME}/.kodi/userdata/keymaps/harmony_remote.xml
sed -i '/FullScreen/d' ${HOME}/.kodi/userdata/keymaps/harmony_remote.xml
sed -i "s|XBMC.ShutDown()||g" ${HOME}/.kodi/userdata/keymaps/harmony_remote.xml

### Fifth: Create a post-install task to configure Kodi:
#==============================================================================
[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
cat << EOF > /usr/local/finisher/tasks.d/50_kodi.sh
#!/bin/bash
USERNAME=\$(id -un 1000 2> /dev/null)
sed -i "s|\"network.httpproxypassword\">.*<|\"network.httpproxypassword\">\${PASSWORD:-"xubuntu"}<|g" /home/\${USERNAME}/.kodi/userdata/guisettings.xml
sed -i "s|\"network.httpproxyusername\">.*<|\"network.httpproxyusername\">\${USERNAME}<|g" /home/\${USERNAME}/.kodi/userdata/guisettings.xml
EOF
chmod +x /usr/local/finisher/tasks.d/50_kodi.sh
