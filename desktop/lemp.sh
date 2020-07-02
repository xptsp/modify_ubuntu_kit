#==============================================================================
_title "Installing MariaSQL"
#==============================================================================
# First: Install the software:
apt install -y mariadb-server
ischroot && systemctl disable mysql

# Second: Secure the MYSQL database software:
mysql --user=root <<_EOF_
UPDATE mysql.user SET Password=PASSWORD("${db_root_password:-"xubuntu"}") WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
