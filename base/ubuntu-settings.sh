#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Customizes a few settings on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Disable notifying about new LTS upgrades..."
#==============================================================================
sed -i "s|Prompt=.*|Prompt=never|g" /etc/update-manager/release-upgrades

#==============================================================================
_title "Setup automatic removal of new unused dependencies..."
#==============================================================================
sed -i "s|//Unattended-Upgrade::Remove-Unused-Dependencies \"false\";|Unattended-Upgrade::Remove-Unused-Dependencies "true";|g" /etc/apt/apt.conf.d/50unattended-upgrades

#==============================================================================
_title "Keep the annoying ${BLUE}\"System Program Problem Detected\"${BLUE} dialog from popping up..."
#==============================================================================
sed -i "s|enabled=1|enabled=0|g" /etc/default/apport

#==============================================================================
_title "Adding finisher task to change default timeout in GRUB to 1 second..."
#==============================================================================
add_bootd 15_grub_timeout.sh

#==============================================================================
_title "Copying \".bashrc\" and \".profile\" from \"/etc/skel\" to \"root\"..."
#==============================================================================
FILE=~/.bash_aliases
wget https://gist.githubusercontent.com/xptsp/5ea4bc39b07d4bb6c1fbf25f4a63a970/raw/3a1678133d6b1a052120d23ae9282260605cd9e7/.bash_aliases -O ${FILE}
chmod +x ${FILE}

cp /etc/skel/.{bash,pro}* /root
FILE=/root/.bashrc
sed -i "s|32m|31m|" ${FILE}
sed -i "s|# don't put|HOME=\$\(cat /etc/passwd \| grep -e "^\${SUDO_USER}:" \| cut -d: -f 6\)\n\n# don't put|" ${FILE}

#==============================================================================
_title "Adding new value under \"/etc/sudoers.d/\"..."
# Inspired by: https://www.gamingonlinux.com/2024/03/ubuntu-2404-increases-vm-max-map-count-for-smoother-linux-gaming/
#==============================================================================
sed -i "/vm.max_map_count/d" /etc/sysctl.d/*.conf
echo "vm.max_map_count = 1048576" > /etc/sysctl.d/98-custom-optimization.conf
