#!/bin/bash
# Generate new SSH keys for this install:
dpkg-reconfigure openssh-server

# Generate new identy for user 1000:
USER=$(grep ":1000:" /etc/passwd | cut -d: -f 1)
HOME=$(grep -m 1 "^${USER}:" /etc/passwd | cut -d: -f 6)
if [[ ! -f ${HOME}/.ssh/id_rsa ]]; then
	mkdir -p ${HOME}/.ssh
	ssh-keygen -f ${HOME}/.ssh/id_rsa -N ""
	chown ${USER}:${USER} -R ${HOME}/.ssh 
	chmod 644 ${HOME}/.ssh/*
fi
