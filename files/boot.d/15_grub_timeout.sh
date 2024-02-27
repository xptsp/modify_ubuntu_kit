#!/bin/bash
sed -i "s|GRUB_TIMEOUT=.*|GRUB_TIMEOUT=1|g" /etc/default/grub
echo "GRUB_RECORDFAIL_TIMEOUT=\$GRUB_TIMEOUT" >> /etc/default/grub
update-grub
