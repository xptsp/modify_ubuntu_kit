#!/bin/bash
F=/etc/fstab

# Create ramdisk storage on "/tmp":
sed -i "/^tmpfs/d" $F
echo "tmpfs /tmp tmpfs defaults 0 0" >> $F

# Bind "/home/img" to "/img":
mkdir -p /home/img
sed -i "/\/home\/img/d" $F
echo "/home/img /img none bind 0 0" >> $F

# Default options per filesystem type:
declare -A FS=()
FS[ntfs]=noatime,rw,nosuid,nodev,relatime,uid=1000,gid=1000,fmask=0111,dmask=0022
FS[vfat]=${ntfs}

# Identify first user and their home directory:
USER=$(grep ":1000:" /etc/passwd | cut -d: -f 1)
HOME=$(cat /etc/passwd | grep -m 1 "^doug" | cut -d: -f 6)

# If a partition with the username of user 1000 plus "_Public", mount it to "/home/{USER}/Public" in "/etc/fstab":
DEV=$(blkid | grep -i "\"${USER}_Public\"" | cut -d: -f 1)
if [[ ! -z "$DEV" ]]; then
	eval `blkid -o export ${DEV}`
	sed -i "/\/home\/${USER}\/Public/d" $F
	echo "UUID=${UUID} ${HOME}/Public ${TYPE} ${FS[$TYPE]:-"defaults,noatime"} 0 0" >> $F
	mount ${HOME}/Public
	mkdir -p ${HOME}/Public/Downloads
	sed -i "/\/home\/${USER}\/Public\/Downloads/d" $F
	echo "${HOME}/Public/Downloads ${HOME}/Downloads none bind 0 0" >> $F
fi

# If a partition with the username of user 1000 plus "_Documents", mount it to "/home/{USER}/Documents" in "/etc/fstab":
DEV=$(blkid | grep -i "\"${USER}_Documents\"" | cut -d: -f 1)
UUID=$(blkid -o export $DEV | grep "^UUID=" | cut -d= -f 2)
if [[ ! -z "$DEV" ]]; then
	eval `blkid -o export ${DEV}`
	sed -i "/\/home\/${USER}\/Documents/d" $F
	echo "UUID=${UUID} ${HOME}/Documents ${TYPE} ${FS[$TYPE]:-"defaults,noatime"} 0 0" >> $F
	mount ${HOME}/Documents
	mkdir -p ${HOME}/Documents/GitHub
	sed -i "/\/home\/${USER}\/Documents\/GitHub/d" $F
	echo "${HOME}/Documents/GitHub ${HOME}/GitHub none bind 0 0" >> $F
	sed -i "/\/opt\/modify_ubuntu_kit/d" $F
	echo "${HOME}/GitHub/modify_ubuntu_kit  /opt/modify_ubuntu_kit  none bind 0 0" >> $F
fi

# Pretify the "/etc/fstab" file, then mount everything:
cat $F | grep -v "^#" | column -t | tee $F >& /dev/null
mount -a

# Symbolic link to Mozilla Firefox, Thunderbird, and GitHub Desktop folders in Documents if they exist:
mkdir -p ${HOME}/.config
test -d "${HOME}/Documents/.mozilla" && ln -sf "${HOME}/Documents/.mozilla" "${HOME}/.mozilla"
test -d "${HOME}/Documents/.thunderbird" && ln -sf "${HOME}/Documents/.thunderbird" "${HOME}/.thunderbird"
test -d "${HOME}/Documents/.GitHub_Desktop" && ln -sf "${HOME}/Documents/.GitHub_Desktop" "${HOME}/.config/GitHub Desktop"
