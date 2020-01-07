#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs DDClient on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Setup & configure the DDClient daemon..."
#==============================================================================
apt install -y ddclient curl libjson-any-perl libio-socket-ssl-perl sasl2-bin
apt-mark hold ddclient
wget http://downloads.sourceforge.net/project/ddclient/ddclient/ddclient-3.8.3.tar.bz2 -O /tmp/ddclient-3.8.3.tar.bz2
pushd /tmp
tar -jxvf ddclient-3.8.3.tar.bz2
cp -f ddclient-3.8.3/ddclient /usr/sbin/ddclient
rm -rf ddclient*
mkdir /etc/ddclient
mv /etc/ddclient.conf /etc/ddclient/
ln -sf /etc/ddclient/ddclient.conf /etc/ddclient.conf
popd
chmod 600 /etc/ddclient/ddclient.conf
systemctl disable ddclient --dry-run
