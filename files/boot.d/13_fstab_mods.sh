#!/bin/bash
F=/etc/fstab

# Create ramdisk storage on "/tmp":
sed -i "/^tmpfs/d" $F
echo "tmpfs /tmp tmpfs defaults 0 0" >> $F

# Default options per filesystem type:
declare -A FS=()
FS[ntfs]=noatime,rw,nosuid,nodev,relatime,uid=1000,gid=1000,fmask=0111,dmask=0022
FS[vfat]=${ntfs}

# Identify first user and their home directory:
USER=$(grep ":1000:" /etc/passwd | cut -d: -f 1)
HOME=$(grep -m 1 "^${USER}:" /etc/passwd | cut -d: -f 6)

# If a partition with the username of user 1000 plus "_Public", mount it to "/home/{USER}/Public" in "/etc/fstab":
DEV=$(blkid | grep -i "\"${USER}_Public\"" | cut -d: -f 1)
if [[ ! -z "$DEV" ]]; then
	umount ${DEV}
	eval `blkid -o export ${DEV}`
	sed -i "/\/home\/${USER}\/Public/d" $F
	echo "UUID=${UUID} ${HOME}/Public ${TYPE} ${FS[$TYPE]:-"defaults,noatime"} 0 0" >> $F
	mkdir -p ${HOME}/Public
	mount ${HOME}/Public
fi

# If a partition with the username of user 1000 plus "_Documents", mount it to "/home/{USER}/Documents" in "/etc/fstab":
DEV=$(blkid | grep -i "\"${USER}_Documents\"" | cut -d: -f 1)
if [[ ! -z "$DEV" ]]; then
	umount ${DEV}
	eval `blkid -o export ${DEV}`
	sed -i "/\/home\/${USER}\/Documents/d" $F
	echo "UUID=${UUID} ${HOME}/Documents ${TYPE} ${FS[$TYPE]:-"defaults,noatime"} 0 0" >> $F
	mkdir -p ${HOME}/Documents
	mount ${HOME}/Documents
fi

# Symbolic links to Yuzu in Public if they exist:
test -d "${HOME}/Public/.yuzu/config" && mkdir -p ${HOME}/.config/yuzu && ln -sf ${HOME}/Public/.yuzu/config ${HOME}/.config/yuzu
test -d "${HOME}/Public/.yuzu/data" && mkdir -p "${HOME}/.local/share/yuzu" && ln -sf ${HOME}/Public/.yuzu/data ${HOME}/.local/share/yuzu

# Symbolic link to Mozilla Firefox, Thunderbird, and GitHub Desktop folders in Documents if they exist:
mkdir -p ${HOME}/.config
test -d "${HOME}/Documents/.mozilla" && ln -sf "${HOME}/Documents/.mozilla" "${HOME}/.mozilla"
test -d "${HOME}/Documents/.thunderbird" && ln -sf "${HOME}/Documents/.thunderbird" "${HOME}/.thunderbird"
test -d "${HOME}/Documents/.GitHub_Desktop" && ln -sf "${HOME}/Documents/.GitHub_Desktop" "${HOME}/.config/GitHub Desktop"
if [[ -d ${HOME}/Documents/GitHub ]]; then	
	mkdir -p ${HOME}/GitHub
	chown ${USER}:${USER} ${HOME}/GitHub
	sed -i "/\/home\/${USER}\/Documents\/GitHub/d" $F
	echo "${HOME}/Documents/GitHub ${HOME}/GitHub none bind 0 0" >> $F
	mount ${HOME}/GitHub
fi
if [[ -d "${HOME}/GitHub/modify_ubuntu_kit" ]]; then
	sed -i "/\/opt\/modify_ubuntu_kit/d" $F
	echo "${HOME}/GitHub/modify_ubuntu_kit  /opt/modify_ubuntu_kit  none bind 0 0" >> $F
fi
if [[ -d ${HOME}/Public/Downloads ]]; then
	sed -i "/\/home\/${USER}\/Public\/Downloads/d" $F
	echo "${HOME}/Public/Downloads ${HOME}/Downloads none bind 0 0" >> $F
fi

# Pretify the "/etc/fstab" file, then mount everything:
cat $F | grep -v "^#" | column -t | tee $F >& /dev/null
chown ${USER}:${USER} -R ${HOME}/*
systemctl daemon-reload
mount -a
