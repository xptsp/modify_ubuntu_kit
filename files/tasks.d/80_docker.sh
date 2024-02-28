#!/bin/bash
mkdir -p /home/docker/.sys
mkdir -p /var/lib/docker
echo "/home/docker/.sys  /var/lib/docker  none  bind  0  0" >> /etc/fstab

[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)
usermod -aG docker ${USERNAME}
usermod -aG docker docker
