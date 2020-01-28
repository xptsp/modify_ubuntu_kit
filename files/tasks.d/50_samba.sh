#!/bin/bash
[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)
[[ -z "${PASSWORD}" ]] && PASSWORD=xubuntu

(echo ${PASSWORD:-"xubuntu"}; echo ${PASSWORD:-"xubuntu"}) | smbpasswd -a ${USERNAME}
