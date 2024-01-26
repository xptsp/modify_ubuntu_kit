#!/bin/bash
# Add lines to "/etc/fstab":
cat /etc/fstab | grep -v "tmpfs" > /tmp/fstab
mv /tmp/fstab /etc/fstab
cat << DONE >> /etc/fstab
tmpfs  /tmp       tmpfs  defaults  0  0
DONE
