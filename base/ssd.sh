#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Configures SSDs for best performance on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Configuring your computer for best performance..."
#==============================================================================
# First: Add a finisher task to check for SSDs:
#==============================================================================
add_taskd 16_noatime.sh

# Second: Change the TRIM task to run daily:
#==============================================================================
[[ ! -d /etc/systemd/system/fstrim.timer.d ]] && mkdir /etc/systemd/system/fstrim.timer.d
cat << EOF > /etc/systemd/system/fstrim.timer.d/override.conf
[Timer]
OnCalendar=
OnCalendar=daily
EOF

# Third: Limit swap file wearing:
#==============================================================================
cat << EOF >> /etc/sysctl.conf

# Sharply reduce the inclination to swap
vm.swappiness=10
EOF
