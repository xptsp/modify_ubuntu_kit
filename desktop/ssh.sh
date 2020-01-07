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
apt install -y ssh

# Second: Disable SSH and remove the generated SSH keys for security reasons...
#==============================================================================
systemctl disable ssh
rm -v /etc/ssh/ssh_host_*

# Third: Add finisher task to regenerate the SSH keys...
#==============================================================================
[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
cat << EOF > /usr/local/finisher/tasks.d/12_ssh.sh
#!/bin/bash
# Generate new SSH keys for this install:
dpkg-reconfigure openssh-server
EOF
chmod +x /usr/local/finisher/tasks.d/12_ssh.sh
