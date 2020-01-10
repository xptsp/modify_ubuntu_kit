#!/bin/bash
sed -i "s|GRUB_TIMEOUT=.*|GRUB_TIMEOUT=1|g" /etc/default/grub
update-grub
