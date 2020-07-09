#!/bin/bash
if ! cat /etc/fstab | grep "/var/lib/docker" >& /dev/null; then
	[[ ! -d /home/docker/.sys ]] && mkdir -p /home/docker/.sys
	[[ ! -d /var/lib/docker ]] && mkdir -p /var/lib/docker
	echo "/home/docker/.sys  /var/lib/docker  none  bind  0  0" >> /etc/fstab
fi

[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)
usermod -aG docker ${USERNAME}
usermod -aG docker htpc
