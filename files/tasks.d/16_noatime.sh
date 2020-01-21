#!/bin/bash

# Add "noatime" to any hard drives that come up as non-rotational:
[[ ! -f /etc/fstab.bak ]] && cp /etc/fstab /etc/fstab.bak
cat /etc/fstab | grep -e "^UUID=" | grep -v "swap" | grep -v " /boot " > /tmp/mount.txt
while read line; do
	UUID=$(echo $line | cut -d" " -f 1 | cut -d"=" -f 2)
	PART=$(blkid | grep ${UUID} | cut -d":" -f 1 | cut -d"/" -f 3)
	ROT=$(cat /sys/block/${PART:0:3}/queue/rotational)
	if [[ $ROT -eq 0 ]]; then
		MID=$(echo $line | cut -d" " -f 4)
		sed -i "s|${line}|${line/${MID}/noatime,${MID}}|g" /etc/fstab
	fi
done < /tmp/mount.txt
sed -i "s|noatime,noatime,|noatime,|g" /etc/fstab

# Change the scheduler if it isn't optimal for SSDs:
CHANGE=N
for dev in /sys/block/sd?; do
	scheduler=$(echo $dev/queue/scheduler)
	[[ "${schedule}" == "noop deadline [cfq]" ]] && CHANGE=Y
done
if [[ "${CHANGE}" == "Y" ]]; then
	_title "Adding \"elevator=noop\" to \"/etc/default/grub\"..."
	sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="|GRUB_CMDLINE_LINUX_DEFAULT="elevator=noop |g' /etc/default/grub
	update-grub
fi
