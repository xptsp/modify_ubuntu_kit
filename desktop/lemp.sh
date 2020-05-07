#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs a LEMP (Linux/Ngnix/MySQL/PHP) stack on your computer."
	echo ""
	exit 0
fi
 
#==============================================================================
_title "Installing PHP support"
#==============================================================================
# First: Install the software:
add-apt-repository -y universe
apt install -y php-fpm php-opcache php-cli php-gd php-curl php-mysql

# Second: Disable service for chroot environment ONLY:
FPM=$(cd /lib/systemd/system; ls php*-fpm.service)
ischroot && systemctl disable ${FPM}

#==============================================================================
_title "Installing Nginx onto your computer"
#==============================================================================
apt-get -y install nginx
ufw allow 'Nginx HTTP'
ischroot && systemctl disable nginx

#==============================================================================
_title "Installing MySQL"
#==============================================================================
# First: Install the software:
apt install -y mysql-server
ischroot && systemctl disable mysql

# Second: Secure the MYSQL database software:
mysql --user=root <<_EOF_
UPDATE mysql.user SET Password=PASSWORD("${db_root_password:-"xubuntu"}") WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_

# Third: Configure Nginx to use PHP files:
unlink /etc/nginx/sites-enabled/default
cat << EOF > /etc/nginx/sites-available/port_80
server {
        listen 80;
        root /var/www/html;
        index index.php index.html index.htm index.nginx-debian.html;
        server_name example.com;

        location / {
                try_files \$uri \$uri/ =404;
        }

        location ~ \.php\$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/${FPM/.service/.sock};
        }

        location ~ /\.ht {
                deny all;
        }
}
EOF
ln -s /etc/nginx/sites-available/port_80 /etc/nginx/sites-enabled/
