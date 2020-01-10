#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs SickChill on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing SickChill (port 8081)..."
#==============================================================================
# First: Install the dependencies:
#==============================================================================
apt install -y unrar-free git-core openssl libssl-dev python2.7

# Second: Clone the repository:
#==============================================================================
git clone --depth=1 https://github.com/SickChill/SickChill.git /opt/sickchill
relocate_dir /opt/sickchill

# Third: Copy the service file and set defaults:
#==============================================================================
cp /opt/sickchill/runscripts/init.ubuntu /etc/init.d/sickchill
echo "SR_USER=htpc" > /etc/default/sickchill
chown root:root /etc/init.d/sickchill
chmod +x /etc/init.d/sickchill
change_username /etc/default/sickchill

# Fourth: Get the configuration file:
#==============================================================================
unzip ${MUK_DIR}/files/sickchill_settings.zip -d /opt/sickchill/
change_username /opt/sickchill/config.ini

# Fifth: Create finisher task
#==============================================================================
if [[ ! -z "${CHROOT}" ]]; then
	systemctl disable sickchill
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/40_sickchill.sh /usr/local/finisher/tasks.d/40_sickchill.sh
else
	systemctl enable sickchill
	systemctl start sickchill
	${MUK_DIR}/files/tasks.d/40_sickchill.sh
fi	
