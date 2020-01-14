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

# If "--no-xfce" is passed to script, then don't start this if xfce4-session isn't running:
if [[ ! -z "${options[no-xfce]}" ]]; then
	if ! pgrep xfce4-session > /dev/null; then
		_error "Refusing to run script because ${BLUE}xfce4-session${GREEN} not started!"
		exit 1
	fi
fi

# Define the keyiables we need for this script:
export CONFIG_FILE=/usr/local/finisher/tcmount.ini
export TITLE="TrueCrypt Mounter"
export CHROOT=N

# Read in the configuration file:
unset volumes mount before services bind rebind after
while IFS='= ' read key val
do
	# Ignore comments and empty lines:
	if [[ ! -z ${key} && ! ${key} == \#* ]]; then
		if [[ ${key} == \[*] ]]; then
			# Section names must be lowercase and alphanumeric characters only:
			section=$(echo $key | sed 's/[][]//g' | tr '[:upper:]' '[:lower:]')
			[[ ! -z "${options[debug]}" ]] && (echo "[$section]")
		elif [[ ${val} ]]; then
			# Substitute "HOME_DIR" with current home directory, if found:
			[[ ${key} == HOME_DIR/* ]] && key=${key/HOME_DIR/${HOME}}
			[[ ${val} == HOME_DIR/* ]] && val=${val/HOME_DIR/${HOME}}
			[[ ! -z "${options[debug]}" ]] && echo "${key}=${val}"
			# Add the key/value set to the array:
			declare -A "$section[${key}]=${val}"
		fi
	fi
done < ${CONFIG_FILE}

# Create our mounting options string here:
unset MNT
for option in "${!mount[@]}"; do
	MNT="${MNT}$([[ ! -z "${MNT}" ]] && echo ",")$option=${mount[$option]}"
done
[[ ! -z "${MNT}" ]] && MNT="-o ${MNT}"

# Determine what volumes are present and unmounted:
for file in "${!volumes[@]}"; do
	if [[ -e ${file} ]]; then
		PART=$(ls -l $file | cut -d">" -f 2 | cut -d"/" -f 3)
		MNT=$(mount | grep " ${volumes[${file}]} ")
		[[ ! -z "${PART}" && -z "${MNT}" ]] && declare -A "uuid[${file}]=${volumes[${file}]}"
	fi
done
if [[ -z "${!uuid[@]}" ]]; then
	MSG="No unmounted TrueCrypt volumes found!  Exiting..."
	if [[ -z "${options[q]}" && -z "${options[quiet]}" ]]; then
		[[ -z "${DISPLAY}" ]] && _title "${MSG}" || zenity --info --no-wrap --title "${TITLE}" --text="${MSG}"
	fi
	exit 0
fi

# Loop until no volumes left to mount OR user cancels the script:
while [[ ! -z "${!uuid[@]}" ]]; do
	# Was password specified on command-line?  If so, use it!
	if [[ ! -z "${options[p]}" || ! -z "${options[password]}" ]]; then
		[[ -z "${options[p]}" ]] && declare -A "options[p]=${options[password]}"
		PASS=${options[p]}
	# Get the password to use to attempt to open the TrueCrypt volumes:
	elif [[ -z "${DISPLAY}" ]]; then
	    read -s -p "Enter Password: " PASS; echo ""
	else
		PASS=$(zenity --password "Type in your TrueCrypt password:" --title "${TITLE}")
	fi
	[[ -z "${PASS}" || $? -gt 0 ]] && exit 0

	# Attempt to mount the specified partitions using the supplied password:
	for part in "${!uuid[@]}"; do
		dst=${uuid[${part}]}
		[[ ! -d ${dst} ]] && mkdir -p ${dst}
		OUT=$(unset DISPLAY; truecrypt --non-interactive -k "" --protect-hidden=no -p ${PASS} ${part} ${dst} 2>&1)
		if [[ ! -z "${OUT}" ]]; then
			[[ -z "${DISPLAY}" ]] && _error "$OUT" || notify-send --icon=error "${TITLE}" "${OUT}"
		else
			MSG="$(basename ${dst}) mounted successfully!"
			[[ -z "${DISPLAY}" ]] && _title "${MSG}" || notify-send --icon=info "${TITLE}" "${MSG}"
			PART=$(mount | grep "${uuid[${part}]}" | cut -d" " -f 1)
			if [[ ! -z "${MNT}" ]]; then
				umount ${dst} && mount ${MNT} ${PART} ${dst}
			fi
			unset uuid[${part}]
		fi
	done

	# If password was specified on command-line, abort if everything isn't mounted:
	[[ ! -z "${options[p]}" && ! -z "${!uuid[@]}" ]] && exit 1
done

# How many tasks are there to complete?
let tasks=$((${#before[@]}+${#stopped[@]}*2+${#bind[@]}+${#after[@]}))

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
		[[ -d ${dst} &&  -d ${src} ]] && mount --bind ${src} ${dst}
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

# Notify user that this script is finished running:
MSG="${TITLE} has finished running!"
[[ -z "${DISPLAY}" ]] && _title "${MSG}" || notify-send --icon=info "${TITLE}" "${MSG}"
