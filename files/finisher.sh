#!/bin/bash
# Determine where the toolkit is installed:
[[ -e /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e "${MUK_DIR}" ]] && exit 0
[[ -f ${MUK_DIR}/files/includes.sh ]] && . ${MUK_DIR}/files/includes.sh

# Determine which user is user ID 1000:
export USERNAME=$(id -un 1000)
export PASSWORD=xubuntu
alias exit=return

###############################################################################
# Execute any scripts under "/usr/local/finisher/tasks.d":
################################################################################
if [[ -d /usr/local/finisher/tasks.d ]]; then
	for file in /usr/local/finisher/tasks.d/*; do
		if [[ -f "${file}" && -x "${file}" ]]; then
			_title "Executing task in \"${file}\"..."
			${file}
		fi
	done
fi

################################################################################
# Change username in specified files:
################################################################################
if [ -f /usr/local/finisher/username.list ]; then
	echo ""
	while read p r; do
		if [[ -f $p ]]; then
			_title "Changing username in file \"${p}\"..."
			sed -i "s|${r:-kodi}|${USERNAME}|g" $p
		fi
	done < /usr/local/finisher/username.list
fi

################################################################################
# Change password in specified files:
################################################################################
if [ -f /usr/local/finisher/password.list ]; then
	echo ""
	while read p r; do
		if [[ -f $p ]]; then
			_title "Changing password in file \"${p}\"..."
			sed -i "s|${r:-xubuntu}|${PASSWORD}|g" $p
		fi
	done < /usr/local/finisher/password.list
fi

################################################################################
# Change ownership of specified files/folders:
################################################################################
if [ -f /usr/local/finisher/ownership.list ]; then
	echo ""
	while read p; do
		chown ${USERNAME}:${USERNAME} $([[ -d $p ]] && echo "-R") $p
	done < /usr/local/finisher/ownership.list
fi

################################################################################
# Relocate specified folders ONLY if "/" and "/home" are seperate partitions:
################################################################################
PROOT=$(mount | grep " / " | cut -d" " -f 1)
PHOME=$(mount | grep " /home " | cut -d" " -f 1)
if [[ ! "${PROOT}" == "${PHOME}" && -f /usr/local/finisher/relocate.list ]]; then
	echo "\n"
	cat /etc/fstab | grep -v "/home/.relocate" > /tmp/fstab
	mv /tmp/fstab /etc/fstab
	echo "" >> /etc/fstab
	echo "# Redirected storage locations for specified folders under /home/.relocate:" >> /etc/fstab
	[ ! -d /home/.relocate ] && mkdir -p /home/.relocate
	while read p; do
		BASE=$(basename $p)
		_title "Redirecting \"${p}\" to \"/home/.relocate/${BASE}\"...."
		[[ ! -d /home/.relocate/${BASE} ]] && cp -aR $p /home/.relocate/
		echo "$p  /home/.relocate/${BASE}  none  defaults,bind  0  0" >> /etc/fstab
	done < /usr/local/finisher/relocate.list
fi

################################################################################
# Enable all services that need to be enabled for installation:
################################################################################
if [ -f /usr/local/finisher/disabled.list ]; then
	while read p; do
		_title "Enabling service \"${p}\"..."
		systemctl enable $p
	done < /usr/local/finisher/disabled.list
fi

################################################################################
# Execute any scripts under "/usr/local/finisher/post.d":
################################################################################
if [[ -d /usr/local/finisher/post.d ]]; then
	for file in /usr/local/finisher/post.d/*; do
		if [[ -f "${file}" && -x "${file}" ]]; then
			_title "Executing task in \"${file}\"..."
			${file}
		fi
	done
fi

################################################################################
# Return to user:
################################################################################
exit 0
