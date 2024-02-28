#!/bin/bash
[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)
[[ -z "${PASSWORD}" ]] && PASSWORD=$(grep grep "^ID=" /etc/os-release | cut -d= -f 2)

sed -i "s|\"network.httpproxypassword\">.*<|\"network.httpproxypassword\">${PASSWORD}<|g" /home/${USERNAME}/.kodi/userdata/guisettings.xml
sed -i "s|\"network.httpproxyusername\">.*<|\"network.httpproxyusername\">${USERNAME}<|g" /home/${USERNAME}/.kodi/userdata/guisettings.xml
