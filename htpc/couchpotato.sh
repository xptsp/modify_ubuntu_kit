#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs CouchPotato on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing CouchPotato (port 5050)..."
#==============================================================================
# First: Install the dependencies:
#==============================================================================
apt install -y python-lxml libxml2-dev libxslt-dev python-openssl python-cryptography git-core libffi-dev libssl-dev zlib1g-dev libxslt1-dev libxml2-dev python python-pip python-dev build-essential -y

# Second: Clone the repository:
#==============================================================================
git clone --depth=1 https://github.com/RuudBurger/CouchPotatoServer /opt/couchpotato
relocate_dir /opt/couchpotato
change_ownership /opt/couchpotato

# Third : Customize the service file:
#==============================================================================
cp /opt/couchpotato/init/couchpotato.service /etc/systemd/system/couchpotato.service
sed -i "s|/var/lib/CouchPotatoServer|/opt/couchpotato|g" /etc/systemd/system/couchpotato.service
sed -i "s|=couchpotato|=htpc|g" /etc/systemd/system/couchpotato.service
systemctl disable couchpotato

# Fourth: Create finisher task
#==============================================================================
[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
cat << EOF > /usr/local/finisher/tasks.d/40_couchpotato.sh
#!/bin/bash
chown htpc:htpc -R /opt/couchpotato
EOF
chmod +x /usr/local/finisher/tasks.d/40_couchpotato.sh
