#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs TimeShift on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing TimeShift..."
#==============================================================================
# First: Install the software :p
#==============================================================================
apt install -y timeshift

# Second: Add task to the finisher script:
#==============================================================================
add_taskd 70_timeshift.sh
add_bootd zz_timeshift.sh

# Third: Create backup hook script to save initramfs and kernel files if
#  they are located outside the root partition:
#==============================================================================
FILE=/etc/timeshift/backup-hooks.d/backup
mkdir -p $(dirname $FILE)
cat << EOF > ${FILE}
#!/bin/bash
mount | grep -q " /boot " && cp -aRx /boot \${TS_SNAPSHOT_PATH}/@/
EOF
chmod +x ${FILE}

# Fourth: Create restore hook script to restore initramfs and kernel files if
#  they are located outside the root partition:
#==============================================================================
FILE=/etc/timeshift/restore-hooks.d/backup
mkdir -p $(dirname $FILE)
cat << EOF > ${FILE}
#!/bin/bash
mount | grep -q " /boot " || exit 0
rm -rf /boot/*
cp -aRx \${TS_SNAPSHOT_PATH}/@/boot/* /boot/
EOF
chmod +x ${FILE}
