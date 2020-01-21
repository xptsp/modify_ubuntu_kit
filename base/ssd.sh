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
if ischroot; then
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
	ln -sf ${MUK_DIR}/files/tasks.d/16_noatime.sh /usr/local/finisher/tasks.d/16_noatime.sh
else
	${MUK_DIR}/files/tasks.d/16_noatime.sh
fi

# Second: Change the TRIM task to run daily:
#==============================================================================
mkdir /etc/systemd/system/fstrim.timer.d
cat << EOF > mkdir -v /etc/systemd/system/fstrim.timer.d/override.conf
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
