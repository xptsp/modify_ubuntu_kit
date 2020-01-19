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
if ischroot; then
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/15_grub_timeout.sh /usr/local/finisher/tasks.d/15_grub_timeout.sh
else
	${MUK_DIR}/files/tasks.d/15_grub_timeout.sh
fi
