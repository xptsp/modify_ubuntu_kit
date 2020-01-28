#!/bin/bash
[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)
[[ -z "${PASSWORD}" ]] && PASSWORD=xubuntu

sed -i "s|\"network.httpproxypassword\">.*<|\"network.httpproxypassword\">${PASSWORD:-"xubuntu"}<|g" /home/${USERNAME}/.kodi/userdata/guisettings.xml
sed -i "s|\"network.httpproxyusername\">.*<|\"network.httpproxyusername\">${USERNAME}<|g" /home/${USERNAME}/.kodi/userdata/guisettings.xml
