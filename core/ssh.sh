#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs SSH on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing and configuring SSH..."
#==============================================================================
# First: Install the software (duh :p)
#==============================================================================
apt install -y ssh toilet
sed -i "s|#ClientAliveInterval .*|ClientAliveInterval 60|g" /etc/ssh/sshd_config
sed -i "s|#ClientAliveCountMax .*|ClientAliveCountMax 3|g" /etc/ssh/sshd_config
systemctl restart sshd

# Second: Configure as appropriate:
#==============================================================================
ischroot && (systemctl disable ssh; rm -v /etc/ssh/ssh_host_*)
add_taskd 12_ssh.sh

# Third: Configure the SSH login screen:
#==============================================================================
_title "Configuring SSH login screen..."
#==============================================================================
test -e /etc/motd && rm /etc/motd
ln -s /var/run/motd /etc/motd
DIR=/etc/update-motd.d
test -e ${DIR}/10-uname && rm ${DIR}/10-uname
wget https://raw.githubusercontent.com/xptsp/bpiwrt-builder/master/files/etc/update-motd.d/00-header -O ${DIR}/00-header
wget https://raw.githubusercontent.com/xptsp/bpiwrt-builder/master/files/etc/update-motd.d/10-sysinfo -O ${DIR}/10-sysinfo
wget https://raw.githubusercontent.com/xptsp/bpiwrt-builder/master/files/etc/update-motd.d/99-footer -O ${DIR}/99-footer
chmod +x ${DIR}/*
test -e ${DIR}/10-help-text && rm ${DIR}/10-help-text
test -e ${DIR}/91-contract-ua-esm-status && rm ${DIR}/91-contract-ua-esm-status
