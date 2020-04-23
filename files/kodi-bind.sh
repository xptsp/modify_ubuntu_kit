#!/bin/bash
if [[ ! -f /etc/sudoers.d/kodi-bind && ! "$1"=="-f" ]]; then
    echo "ERROR: /etc/sudoers.d/kodi-bind not found!  Aborting!"
elif ! mount | grep "/mnt/hdd"; then
    echo "WARNING: /mnt/hdd not mounted yet!"
elif [[ -d /mnt/hdd/.kodi ]]; then
    mount --bind /mnt/hdd/.kodi ${HOME}/.kodi
fi
