#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Transmission and TransGUI on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Nginx to be a reverse proxy to our services"
#==============================================================================
apt-get -y install nginx php-fpm php-zip apache2-utils
systemctl disable nginx
systemctl disable php7.2-fpm
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
