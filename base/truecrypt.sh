#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs TrueCrypt on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing and Configuring TrueCrypt..."
#==============================================================================
# First: Install the software:
add-apt-repository -y ppa:stefansundin/truecrypt
apt install -y truecrypt

# Second: Stop TrueCrypt from automatically starting without "xfce4-session" running:
#==============================================================================
ln -sf ${MUK_DIR}/files/start-truecrypt /usr/local/bin/start-truecrypt
sed -i "s|Exec=/usr/bin/truecrypt|Exec=/usr/local/bin/start-truecrypt|g" /etc/xdg/autostart/truecrypt.desktop

# Third: Adding TrueCrypt mounter to OS:
#==============================================================================
# Binary:
ln -sf ${MUK_DIR}/files/tcmount.sh /usr/local/bin/tcmount
ln -sf ${MUK_DIR}/files/tcumount.sh /usr/local/bin/tcumount
# Application:
ln -sf ${MUK_DIR}/files/tcmount.desktop /usr/share/applications/
# Icon:
ln -sf ${MUK_DIR}/files/truecrypt.xpm /usr/share/icons/
# Configuration File:
[[ ! -e /usr/local/finisher/tcmount.ini ]] && cp ${MUK_DIR}/files/tcmount.ini /usr/local/finisher/

# Fourth: Create sudoers.d rule to run truecrypt mounter as root:
#==============================================================================
echo "ALL ALL=(ALL) NOPASSWD:/usr/bin/truecrypt,/usr/local/bin/tcmount,/usr/local/bin/tcumount" >> /etc/sudoers.d/truecrypt

# Fifth: Add the finisher script:
#==============================================================================
if ischroot; then
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/70_truecrypt.sh /usr/local/finisher/tasks.d/70_truecrypt.sh
else
	${MUK_DIR}/files/tasks.d/70_truecrypt.sh
fi
