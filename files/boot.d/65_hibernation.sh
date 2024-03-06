#!/bin/bash

# If no swap partition exists, exit with error code 0:
DEV=$(blkid | grep swap | cut -d":" -f 1)
[[ -z "${DEV}" ]] && exit 0
UUID=$(blkid -o export ${DEV} | grep "^UUID=" | cut -d= -f 2)
[[ -z "${UUID}" ]] && exit 0

# Add UUID to grub configuration:
FILE=/etc/default/grub
eval `grep GRUB_CMDLINE_LINUX_DEFAULT ${FILE}`
sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${GRUB_CMDLINE_LINUX_DEFAULT} RESUME=UUID=${UUID}\"|" ${FILE}

# Write the resume UUID for initramfs:
echo RESUME=UUID=${UUID} > /etc/initramfs-tools/conf.d/resume
update-initramfs -c -k all
