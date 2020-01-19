#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs USB device wakeup fix on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Create "missing" /etc/rc.local file..."
#==============================================================================
[[ ! -f /etc/rc.local ]] && cat << EOF > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0
EOF
chmod +x /etc/rc.local

# Create finisher task to keep USB devices from waking up computer
#==============================================================================
if ischroot; then
	[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/{tasks,post}.d
	ln -sf ${MUK_DIR}/files/tasks.d/14_usb_wakeup.sh /usr/local/finisher/tasks.d/14_usb_wakeup.sh
else
	${MUK_DIR}/files/tasks.d/14_usb_wakeup.sh
fi
