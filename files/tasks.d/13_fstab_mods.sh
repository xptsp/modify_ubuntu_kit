#!/bin/bash
F=/etc/fstab

# Create ramdisk storage on "/tmp":
sed -i "/^tmpfs/d" $F
cat << DONE >> $F
tmpfs /tmp tmpfs defaults 0 0
DONE

# If my Windows partition is present, add it to "/etc/fstab":
DEV=$(grep "Windows Boot Manager" /boot/grub/grub.cfg | awk '{print $6}' | cut -d\) -f 1)
UUID=$(blkid -o export $DEV | grep "^UUID=" | cut -d= -f 2)
if [[ ! -z "$UUID" ]]; then
	mkdir -p /mnt/Windows
	sed -i "/\/mnt\/Windows/d" $F
	echo "UUID=${UUID} /mnt/Windows ntfs rw,nosuid,nodev,relatime,uid=1000,gid=1000,fmask=0111,dmask=0022 0 0" >> $F
fi

# If a partition with the username of user 1000 plus "_Public", mount it to "/home/{USER}/Public" in "/etc/fstab":
USER=$(grep ":1000:" /etc/passwd | cut -d: -f 1)
DEV=$(blkid | grep -i "\"${USER}_Public\"" | cut -d: -f 1)
UUID=$(blkid -o export $DEV | grep "^UUID=" | cut -d= -f 2)
if [[ -z "$UUID" ]]; then
	sed -i "/\/home\/doug\/Public/d" $F
	echo "UUID=${UUID} /home/doug/Public ntfs noatime,rw,nosuid,nodev,relatime,uid=1000,gid=1000,fmask=0111,dmask=0022 0 0" >> $F
	sed -i "/\/home\/doug\/Public\/Downloads/d" $F
	echo "/home/doug/Public/Downloads /home/doug/Downloads none bind 0 0" >> $F
fi

# If a partition with the username of user 1000 plus "_Documents", mount it to "/home/{USER}/Documents" in "/etc/fstab":
DEV=$(blkid | grep -i "\"${USER}_Documents\"" | cut -d: -f 1)
UUID=$(blkid -o export $DEV | grep "^UUID=" | cut -d= -f 2)
if [[ -z "$UUID" ]]; then
	sed -i "/\/home\/doug\/Documents/d" $F
	echo "UUID=${UUID} /home/doug/Documents ext4 defaults,noatime 0 0" >> $F
	sed -i "/\/home\/doug\/Documents\/GitHub/d" $F
	echo "/home/doug/Documents/GitHub /home/doug/GitHub none bind 0 0" >> $F
	echo "/home/doug/GitHub/modify_ubuntu_kit  /opt/modify_ubuntu_kit  none bind 0 0" >> $F
fi

# If my Ubuntu USB installation stick is present, add it to "/etc/fstab":
if blkid | grep -q "\"b72b7891-f821-42bb-b457-8a3878e8a46a\""; then
	mkdir -p /img
	echo "/home/img /img none bind 0 0" >> $F
	mkdir -p /home/img/usb_{casper,live}
	sed -i "/UUID=b72b7891-f821-42bb-b457-8a3878e8a46a/d" $F
	echo "UUID=b72b7891-f821-42bb-b457-8a3878e8a46a /home/img/usb_casper ext4 noatime,defaults,noatime 0 0" >> $F
	sed -i "/UUID=C198-307D/d" $F
	echo "UUID=C198-307D /home/img/usb_live vfat noatime,rw,nosuid,nodev,relatime,uid=1000,gid=1000,fmask=0111,dmask=0022 0 0" >> $F
	mkdir -p /img/mnt
	sed -i "/^unionfs\#/d" $F
	echo "unionfs#/home/img/usb_casper=rw:/home/img/usb_live=rw /home/img/mnt fuse default_permissions,allow_other,use_ino,nonempty,suid,cow 0 0" >> $F
fi

# Pretify the "/etc/fstab" file, then mount everything:
cat $F | grep -v "^#" | column -t | tee $F
mount -a
