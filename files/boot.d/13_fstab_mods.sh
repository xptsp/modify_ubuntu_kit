#!/bin/bash
F=/etc/fstab

# Default options per filesystem type:
declare -A FS=()
FS[ntfs]=rw,nosuid,nodev,relatime,uid=1000,gid=1000,fmask=0111,dmask=0022
FS[vfat]=${ntfs}

function mount_partition() {
	local DEV="$2"
	if [[ ! -z "${DEV}" ]]; then
		umount ${DEV}
		eval `blkid -o export ${DEV}`
		local DIR=$1
		sed -i "/ ${DIR//\//\\\/} /d" /etc/fstab
		echo "UUID=${UUID}  ${1} ${TYPE}  ${FS[$TYPE]:-"defaults"}  0  2" >> $F
		mkdir -p "${DIR}"
		mount "${DIR}"
	fi
}
function bind_directory()
{
	local SRC="$1"
	local DST="$2"
	if [[ -d "${SRC}" ]]; then
		mkdir -p "${DST}"
		chown ${USER}:${USER} ${DST}
		sed -i "/ ${DST//\//\\\/} /d" /etc/fstab
		echo "${SRC}  ${DST// /\\040}  none  bind  0  0" >> $F
		mount ${DST}
	fi
}

# Identify first user and their home directory:
USER=$(grep ":1000:" /etc/passwd | cut -d: -f 1)
HOME=$(grep -m 1 "^${USER}:" /etc/passwd | cut -d: -f 6)

# If a partition with the username of user 1000 plus "_Public", mount it to "/home/{USER}/Public" in "/etc/fstab":
mount_partition "${HOME}/Public" "$(blkid | grep -i "\"${USER}_Public\"" | cut -d: -f 1)"

# If a partition with the username of user 1000 plus "_Documents", mount it to "/home/{USER}/Documents" in "/etc/fstab":
mount_partition "${HOME}/Documents" "$(blkid | grep -i "\"${USER}_Documents\"" | cut -d: -f 1)"

# Create mount bindings for a copy of modify_ubuntu_kit in GitHub folder to "/opt":
bind_directory "${HOME}/Documents/GitHub/modify_ubuntu_kit" /opt/modify_ubuntu_kit

# Create mount bindings for a copy of modify_ubuntu_kit in GitHub folder to "/opt":
bind_directory "${HOME}/Documents/Downloads" "${HOME}/Downloads"

# Create mount bindings for Mozilla Firefox, Thunderbird, and GitHub Desktop folders in Documents if they exist:
bind_directory "${HOME}/Documents/.mozilla" "${HOME}/.mozilla"
bind_directory "${HOME}/Documents/.thunderbird" "${HOME}/.thunderbird"
bind_directory "${HOME}/Documents/.GitHub_Desktop" "${HOME}/.config/GitHub Desktop"
bind_directory "${HOME}/Documents/GitHub" "${HOME}/GitHub"
bind_directory "${HOME}/Documents/.ssh_keys" "${HOME}/.ssh"

# Create mount bindings for Yuzu & Eden directories:
bind_directory "${HOME}/Documents/.yuzu_config" "${HOME}/.config/yuzu"
bind_directory "${HOME}/Documents/.yuzu_data" "${HOME}/.local/share/yuzu"
bind_directory "${HOME}/Documents/.eden_config" "${HOME}/.config/eden"
bind_directory "${HOME}/Documents/.eden_data" "${HOME}/.local/share/eden"

# Finally, let's pretify the "/etc/fstab" file:
test -f ${F}.old || cp ${F}{,.old}
cat ${F} | grep -v "^#" | column -t | tee ${F}.new >& /dev/null
mv ${F}{.new,}
