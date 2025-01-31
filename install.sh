#!/bin/bash

# If we are not running as root, then run this script as root:
if [[ "$EUID" -ne 0 ]]; then
	sudo $0 $@
	exit $?
fi

# Create the finisher and the tasks.d directory:
[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d

# Determine the toolkit's directory name and save it to the configuration file:
MUK_DIR=$(cd $(dirname $0); pwd)
. ${MUK_DIR}/files/includes.sh
grep -q "${MUK_DIR}" /usr/local/finisher/settings.conf || sed -i "s|MUK_DIR=.*|MUK_DIR="${MUK_DIR}"|g" /usr/local/finisher/settings.conf

# Copy the default settings file to the finisher directory:
test -f /usr/local/finisher/settings.conf || cp ${MUK_DIR}/files/settings.conf /usr/local/finisher/settings.conf

# Copy the default tcmount config file to the finisher directory:
test -f /usr/local/finisher/tcmount.ini || cp ${MUK_DIR}/files/tcmount.ini /usr/local/finisher/tcmount.ini

# Link the "edit_chroot" tool to the destination folder:
test -e /usr/local/bin/edit_chroot || ln -sf ${MUK_DIR}/edit_chroot.sh /usr/local/bin/edit_chroot

# Create target-config task in order to run "finisher.sh" ONLY if ubiquity is installed:
if [[ -d /usr/lib/ubiquity/target-config ]]; then 
 	test -e /usr/lib/ubiquity/target-config/99_finisher || ln -sf ${MUK_DIR}/files/tasks.d/99_finisher.sh /usr/lib/ubiquity/target-config/99_finisher
 	FILE=/etc/rc.local
 	test -e ${FILE} || cp ${MUK_DIR}/files/rc.local ${FILE}
 	grep -q "files/muk_boot.sh" ${FILE} || sed -i "s|^exit 0|${MUK_DIR}/files/muk_boot.sh\n\n&|" ${FILE}
	sed -i "s|^${MUK_DIR}/files/firstboot.sh|${MUK_DIR}/files/muk_boot.sh|" ${FILE}
 	test -d /usr/local/finisher/boot.d || mkdir -p /usr/local/finisher/{boot,tasks,post}.d
 	test -e /usr/local/finisher/boot.d/99_update-grub || ln -sf /usr/sbin/update-grub /usr/local/finisher/boot.d/99_update-grub
fi

# Don't require password for the "edit_chroot" command: 
test -f /etc/sudoers.d/edit_chroot || echo "ALL ALL=(ALL) NOPASSWD:/usr/local/bin/edit_chroot" > /etc/sudoers.d/edit_chroot
