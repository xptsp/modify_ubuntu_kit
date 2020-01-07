#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs XRDP on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install XRDP (Remote Desktop server)..."
#==============================================================================
# First: Install the software:
add-apt-repository -y ppa:martinx/xrdp-hwe-18.04
apt install -y xrdp
adduser xrdp ssl-cert
systemctl disable xrdp

# Second: Configuring XRDP properly:
#==============================================================================
### Firsh: Alter the configuration a little:
sed -i -e 's/^new_cursors=true/new_cursors=false/g' /etc/xrdp/xrdp.ini
### Second: Create ~/.xsession and ~/.xsessionrc:
echo "xfce4-session" > ~/.xsession
cat << EOF > ~/.xsessionrc
export XDG_SESSION_DESKTOP=xubuntu
export XDG_DATA_DIRS=/usr/share/xfce4:/usr/share/xubuntu:/usr/local/share:/usr/share:/var/lib/snapd/desktop:/usr/share
export XDG_CONFIG_DIRS=/etc/xdg/xdg-xubuntu:/etc/xdg:/etc/xdg
EOF

# Third: Disabling light-locker when running via XRDP:
#==============================================================================
### Fourth: :
[ ! -f /usr/bin/light-locker.orig ] && mv /usr/bin/light-locker /usr/bin/light-locker.orig
cat <<EOF | tee /usr/bin/light-locker
#!/bin/sh

# The light-locker uses XDG_SESSION_PATH provided by lightdm.
if [ ! -z "\${XDG_SESSION_PATH}" ]; then
  /usr/bin/light-locker.orig
else
  # Disable light-locker in XRDP.
  true
fi
EOF
chmod a+x /usr/bin/light-locker
