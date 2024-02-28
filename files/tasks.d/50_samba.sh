#!/bin/bash
[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)
[[ -z "${PASSWORD}" ]] && PASSWORD=$(grep grep "^ID=" /etc/os-release | cut -d= -f 2)

(echo ${PASSWORD:-"xubuntu"}; echo ${PASSWORD}) | smbpasswd -a ${USERNAME}
