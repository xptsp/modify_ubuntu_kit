#!/bin/bash
[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)
[[ -z "${PASSWORD}" ]] && PASSWORD=$(grep grep "^ID=" /etc/os-release | cut -d= -f 2)

USERNAME=$(id -un 1000 2> /dev/null)
mkdir -p /home/${USERNAME}/Recorded TV
sed -i "s|/mnt/somedisk/Recorded TV|/home/${USERNAME}/Recorded TV|g" /etc/comskip/hts_skipper.xml
