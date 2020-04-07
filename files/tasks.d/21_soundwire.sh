#!/bin/bash
[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)
if [[ -f /etc/skel/.config/openbox/autostart ]]; then
    echo "/opt/SoundWireServer/start-soundwire" >> /etc/skel/.config/openbox/autostart
    cp /etc/skel/.config/openbox/autostart /home/${USERNAME}/.config/openbox/autostart
fi