#!/bin/bash
if ! cat /etc/fstab | grep "/var/lib/docker" >& /dev/null; then
	[[ ! -d /home/docker ]] && mkdir -p /home/docker
	[[ ! -d /var/lib/docker ]] && mkdir -p /var/lib/docker
	echo "/home/docker  /var/lib/docker  none  bind  0  0" >> /etc/fstab
fi
