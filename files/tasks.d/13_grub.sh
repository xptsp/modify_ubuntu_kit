#!/bin/bash

# Copy the reddragon theme to the boot partition and modify grub settings --ONLY--
#   if boot directory is --NOT-- part of root partition:
if mount | grep "/boot "; then
	DIR=/boot/grub/themes
	mkdir -p ${DIR}
	cp -aR /usr/share/grub/themes/reddragon ${DIR}
	sed -i "s|GRUB_THEME=.*|GRUB_THEME=${DIR}|g" /etc/default/grub
fi

# Update grub configuration:
update-grub
