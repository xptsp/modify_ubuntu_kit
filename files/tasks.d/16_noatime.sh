#!/bin/bash

# Add "noatime" to any hard drives that come up as non-rotational:
[[ ! -f /etc/fstab.bak ]] && cp /etc/fstab /etc/fstab.bak
cat /etc/fstab | grep -e "^UUID=" | grep -v "swap" | grep -v " /boot " | while read line; do
	UUID=$(echo $line | cut -d" " -f 1 | cut -d"=" -f 2)
	PART=$(blkid | grep ${UUID} | cut -d":" -f 1 | cut -d"/" -f 3)
	ROT=$(cat /sys/block/${PART:0:3}/queue/rotational)
	if [[ $ROT -eq 0 ]]; then
		MID=$(echo $line | cut -d" " -f 4)
		sed -i "s|${line}|${line/${MID}/${MID},noatime}|g" /etc/fstab
	fi
done
sed -i "s|noatime,noatime|noatime|g" /etc/fstab
