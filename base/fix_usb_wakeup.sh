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
[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/{tasks,post}.d
cat << EOF > /usr/local/finisher/tasks.d/10_rc.local.sh
#!/bin/bash
(/usr/bin/lspci | grep USB; /usr/bin/lspci | grep Ethernet) | cut -d " " -f 1 > /tmp/t7s1 && \
cat /proc/acpi/wakeup > /tmp/t7s2 && \
grep -f /tmp/t7s1 /tmp/t7s2 > /tmp/t7s3 && \
cat /tmp/t7s3 | cut -c 1-4 > /tmp/t7s4 && \
sed -i -e 's/^/echo "/' /tmp/t7s4 && \
sed -i 's/$/" > \/proc\/acpi\/wakeup/' /tmp/t7s4 && \
(head -n -1 /etc/rc.local; cat /tmp/t7s4; tail -1 /etc/rc.local) > /tmp/rc.local && \
mv /tmp/rc.local /etc/rc.local && \
chmod +x /etc/rc.local
EOF
chmod +x /usr/local/finisher/tasks.d/10_rc.local.sh
