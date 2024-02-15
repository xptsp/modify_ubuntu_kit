#!/bin/bash
F=/etc/fstab

# Create ramdisk storage on "/tmp":
sed -i "/^tmpfs/d" $F
cat << DONE >> $F
tmpfs /tmp tmpfs defaults 0 0
DONE

# If my Windows partition is present, add it to "/etc/fstab":
if blkid | grep -q "\"A4A4659DA465732A\""; then
	mkdir -p /mnt/Windows
	sed -i "/UUID=A4A4659DA465732A/d" $F
	echo "UUID=A4A4659DA465732A /mnt/Windows ntfs rw,nosuid,nodev,relatime,uid=1000,gid=1000,fmask=0111,dmask=0022 0 0" >> $F
fi

# If my Ubuntu USB installation stick is present, add it to "/etc/fstab":
if blkid | grep -q "\"b72b7891-f821-42bb-b457-8a3878e8a46a\""; then
	mkdir -p /img/usb_{casper,live}
	sed -i "/UUID=b72b7891-f821-42bb-b457-8a3878e8a46a/d" $F
	echo "UUID=b72b7891-f821-42bb-b457-8a3878e8a46a /img/usb_casper ext4 noatime,defaults,noatime 0 0" >> $F
	sed -i "/UUID=C198-307D/d" $F
	echo "UUID=C198-307D /img/usb_live vfat noatime,rw,nosuid,nodev,relatime,uid=1000,gid=1000,fmask=0111,dmask=0022 0 0" >> $F
	mkdir -p /img/mnt
	sed -i "/^unionfs\#/d" $F
	echo "unionfs#/img/usb_casper=rw:/img/usb_live=rw /img/mnt fuse default_permissions,allow_other,use_ino,nonempty,suid,cow 0 0" >> $F
fi

# If my external hard drive is present, add it to "/etc/fstab":
if blkid | grep -q "\"1109A7497BFE26A3\""; then
	sed -i "/UUID=1109A7497BFE26A3/d" $F
	echo "UUID=1109A7497BFE26A3 /home/doug/Public ntfs noatime,rw,nosuid,nodev,relatime,uid=1000,gid=1000,fmask=0111,dmask=0022 0 0" >> $F
	sed -i "/\/home\/doug\/Public\/Downloads/d" $F
	echo "/home/doug/Public/Downloads /home/doug/Downloads none bind 0 0" >> $F
fi
if blkid | grep -q "\"076ae757-89b6-4f2c-ae64-391069c9d942\""; then
	sed -i "/UUID=076ae757-89b6-4f2c-ae64-391069c9d942/d" $F
	echo "UUID=076ae757-89b6-4f2c-ae64-391069c9d942 /home/doug/Documents ext4 defaults,noatime 0 0" >> $F
	sed -i "/\/home\/doug\/Documents\/GitHub/d" $F
	echo "/home/doug/Documents/GitHub /home/doug/GitHub none bind 0 0" >> $F
fi

# Pretify the "/etc/fstab" file, then mount everything:
cat $F | grep -v "^#" | column -t | tee $F
mount -a
