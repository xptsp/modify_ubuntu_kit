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
test -f /etc/apt/sources.list.d/xptsp_ppa.list || ${MUK_DIR}/base/custom-xptsp.sh
apt install -y reddragon-motd
