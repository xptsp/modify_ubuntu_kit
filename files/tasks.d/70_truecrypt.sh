#!/bin/bash
[[ ! -d /home/docker ]] && mkdir -p /home/docker
[[ ! -f /home/docker/tcmount.ini ]] && cp /usr/local/finisher/tcmount.ini /home/docker/
echo "/home/docker/tcmount.ini  /usr/local/finisher/tcmount.ini  none  bind  0  0" >> /etc/fstab
