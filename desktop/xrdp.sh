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
# Src: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1817225/comments/25
#==============================================================================
[[ "$OS_VER" -eq 1804 ]] && add-apt-repository -y ppa:martinx/xrdp-hwe-18.04
apt install -y xrdp light-locker
adduser xrdp ssl-cert
if ischroot; then
	systemctl disable xrdp
	sed -i '/xrdp/d' /usr/local/finisher/disabled.list
fi

# Second: Fix the "second session" issue with 18.04.x:
# Src: https://catch22cats.blogspot.com/2018/05/xrdp-blank-screen-with-ubuntu-1804.html
#==============================================================================
sed -i "s|test -x /etc/X11/Xsession|unset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\n. \$HOME/.profile\n\ntest -x /etc/X11/Xsession|g" /etc/xrdp/startwm.sh

# Third: Fix the "Authentication Required to Create Managed Color Device" issue:
# Src: https://c-nergy.be/blog/?p=12073
#==============================================================================
[[ -f /etc/polkit-1/localauthority.conf.d/02-allow-colord.conf ]] && rm /etc/polkit-1/localauthority.conf.d/02-allow-colord.conf
cat << EOF > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
[[ -f /var/crash/* ]] && rm /var/crash/*

# Fourth: Configuring XRDP properly:
#==============================================================================
sed -i -e 's/^new_cursors=.*/new_cursors=false/g' /etc/xrdp/xrdp.ini
sed -i -e 's/^allow_channels=.*/allow_channels==false/g' /etc/xrdp/xrdp.ini

# Fifth: Create ~/.xsession and ~/.xsessionrc:
#==============================================================================
echo "xfce4-session" > ~/.xsession
cat << EOF > ~/.xsessionrc
export XDG_SESSION_DESKTOP=xubuntu
export XDG_DATA_DIRS=/usr/share/xfce4:/usr/share/xubuntu:/usr/local/share:/usr/share:/var/lib/snapd/desktop:/usr/share
export XDG_CONFIG_DIRS=/etc/xdg/xdg-xubuntu:/etc/xdg:/etc/xdg
EOF

# Sixth: Disabling light-locker when running via XRDP:
#==============================================================================
### Fourth: :
[ ! -f /usr/bin/light-locker.orig ] && mv /usr/bin/light-locker /usr/bin/light-locker.orig
cat << EOF > /usr/bin/light-locker
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
