#!/bin/bash
# Create the directories we need:
[[ ! -d /home/img/edit ]] && mkdir -p /home/img/{edit,original,mnt}
[[ ! -e /img ]] && ln -sf /home/img /img
[[ ! -e /img/extract ]] && ln -sf /img/original /img/extract

# Add lines to "/etc/fstab":
cat /etc/fstab | grep -v "tmpfs" > /tmp/fstab
mv /tmp/fstab /etc/fstab
cat << DONE >> /etc/fstab

# Mount /tmp and /img/edit directory in RAM (tmpfs):
tmpfs  /img/edit  tmpfs  defaults  0  0
tmpfs  /tmp       tmpfs  defaults  0  0
DONE
