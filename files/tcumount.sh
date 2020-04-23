#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# If we are not running as root, then run this script as root:
if [[ "$EUID" -ne 0 ]]; then
    sudo $0 $@
    exit $?
fi

# Define the keyiables we need for this script:
export CONFIG_FILE=/usr/local/finisher/tcmount.ini
export TITLE="TrueCrypt Unmounter"
export CHROOT=N

# Read in the configuration file:
unset volumes options before services bind rebind after
while IFS='= ' read key val
do
	# Ignore comments and empty lines:
	if [[ ! -z ${key} && ! ${key} == \#* ]]; then
		if [[ ${key} == \[*] ]]; then
			# Section names must be lowercase and alphanumeric characters only:
			section=$(echo ${key//[^[:alpha:].-]/} | sed 's/[][]//g' | tr '[:upper:]' '[:lower:]')
		elif [[ ${val} ]]; then
			# Substitute "HOME_DIR" with current home directory, if found:
			[[ ${key} == HOME_DIR/* ]] && key=${key/HOME_DIR/${HOME}}
			[[ ${val} == HOME_DIR/* ]] && val=${val/HOME_DIR/${HOME}}
			# Add the key/value set to the array:
			declare -A "$section[${key}]=${val}"
		fi
	fi
done < ${CONFIG_FILE}

# Run any commands requested by the settings file before binding directories together:
for cmd in "${before[@]}"; do $cmd; done

# Notify user if we need to have any services that we will be stopping:
systemctl list-unit-files > /tmp/services.list
for service in "${services[@]}"; do
	[[ ! -z "$(cat /tmp/services.list | grep "${service}")" ]] && declare -A "stopped[${service}]=${service}"
done
rm /tmp/services.list
if [[ ! -z "${stopped[@]}" ]]; then
	MSG="Stopping services...  Please wait!"
	[[ -z "${DISPLAY}" ]] && _title "${MSG}" || notify-send --icon=info "${TITLE}" "${MSG}"
	for service in "${stopped[@]}"; do systemctl stop ${service}; done
fi

# Notify user if we need to rebind directories:
if [[ ! -z "${rebind[@]}" || ! -z "${bind[@]}" ]]; then
	MSG="Binding directories together...  Please wait!"
	[[ -z "${DISPLAY}" ]] && _title "${MSG}" || notify-send --icon=info "${TITLE}" "${MSG}"

	# Unmount the specified folders before binding others together:
	for dir in "${rebind[@]}"; do [[ -d ${dir} ]] && umount ${dir} >& /dev/null; done

	# Bind the specified folders together:
	for src in "${!bind[@]}"; do
		dst=${bind[${src}]}
		[[ -d ${dst} &&  -d ${src} ]] && umount ${src}
	done

	# Remount the specified folders umounted earlier:
	for dir in "${rebind[@]}"; do [[ -d ${dir} ]] && mount ${dir} >& /dev/null; done
fi

# Start the specified services:
if [[ ! -z "${stopped[@]}" ]]; then
	MSG="Restarting services...  Please wait!"
	[[ -z "${DISPLAY}" ]] && _title "${MSG}" || notify-send --icon=info "${TITLE}" "${MSG}"
	for service in "${stopped[@]}"; do systemctl start ${service}; done
fi

# Run any commands requested by the settings file before binding directories together:
for cmd in "${after[@]}"; do $cmd; done

# Dismount all Truecrypt volumes:
[[ "$1" == "--kodi" ]] || truecrypt -d -f

# Notify user that this script is finished running:
MSG="${TITLE} has finished running!"
[[ -z "${DISPLAY}" ]] && _title "${MSG}" || notify-send --icon=info "${TITLE}" "${MSG}"
