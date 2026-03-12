#!/bin/bash
F=/etc/fstab

function mount_nfs()
{
	local SRC="$1"
	local DST="$2"
	mkdir -p ${DST}
	chown ${USER}:${USER} ${DST}
	if ! mount -t nfs ${SRC} ${DST}; then rmdir ${DST}; return; fi
	sed -i "/ ${DST//\//\\\/} /d" /etc/fstab
	echo "${SRC}  ${DST// /\\040}  nfs  defaults  0  0" >> $F
}

# Identify first user and their home directory:
USER=$(grep ":1000:" /etc/passwd | cut -d: -f 1)
HOME=$(grep -m 1 "^${USER}:" /etc/passwd | cut -d: -f 6)

# Create mount bindings for certain NFS mounts on the NAS (machine name: nas.lan): 
mount_nfs nas.lan:/hdd "${HOME}/Videos"
mount_nfs nas.lan:/Public "${HOME}/Compile"
