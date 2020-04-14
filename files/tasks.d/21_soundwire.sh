#!/bin/bash
[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)
if [[ -f /etc/skel/.config/openbox/autostart ]]; then
    cat /etc/skel/.config/openbox/autostart | grep -v "start-soundwire" > /tmp/autostart
	echo "/opt/SoundWireServer/start-soundwire" >> /tmp/autostart
	cp /tmp/autostart /home/root/.config/openbox/autostart
	chmod root:root /home/root/.config/openbox/autostart
	if [[ -d /home/htpc/.config/openbox ]]; then	
		cp /tmp/autostart /home/htpc/.config/openbox/autostart
		chmod htpc:htpc /home/htpc/.config/openbox/autostart
	fi
	cp /tmp/autostart /home/${USERNAME}/.config/openbox/autostart
	chmod ${USERNAME}:${USERNAME} /home/${USERNAME}/.config/openbox/autostart
fi