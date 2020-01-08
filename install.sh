#!/bin/bash

# If we are not running as root, then run this script as root:
if [[ "$EUID" -ne 0 ]]; then
	sudo $0 $@
	exit $?
fi

# Create the finisher and the tasks.d directory:
[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d

# Determine the toolkit's directory name and save it to the configuration file:
MUK=$(cd $(dirname $0); pwd)
. ${MUK}/files/includes.sh
sed -i "s|MUK_DIR=.*|MUK_DIR="${MUK}"|g" /usr/local/finisher/settings.conf

# Copy the default settings file to the finisher directory:
[[ ! -z "${options[f]}" || ! -f /usr/local/finisher/settings.conf ]] && cp ${MUK}/files/settings.conf /usr/local/finisher/settings.conf

# Copy the default tcmount config file to the finisher directory:
[[ ! -z "${options[f]}" || ! -f /usr/local/finisher/tcmount.ini ]] && cp ${MUK}/files/tcmount.ini /usr/local/finisher/tcmount.ini

# Link the "edit_chroot" tool to the destination folder:
[[ -e /usr/local/bin/edit_chroot ]] && rm /usr/local/bin/edit_chroot
ln -sf ${MUK}/edit_chroot.sh /usr/local/bin/edit_chroot

# Link the "rdbuild" tool to the destination folder:
[[ -e /usr/local/bin/rdbuild ]] && rm /usr/local/bin/rdbuild
ln -sf ${MUK}/rdbuild.sh /usr/local/bin/rdbuild

# Link the "rdcopy" tool to the destination folder:
[[ -e /usr/local/bin/rdcopy ]] && rm /usr/local/bin/rdcopy
ln -sf ${MUK}/rdcopy.sh /usr/local/bin/rdcopy

# Create target-config task in order to run "finisher.sh" ONLY if ubiquity is installed:
[[ -d /usr/lib/ubiquity/target-config ]] && ln -sf ${MUK}/files/99_finisher.sh /usr/lib/ubiquity/target-config/99_finisher
