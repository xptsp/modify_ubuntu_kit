#!/bin/bash

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs the most current version of Emby Server on your computer."
	echo ""
	exit 0
fi

# If we are not running as root, then run this script as root:
if [[ "$UID" -ne 0 ]]; then
	sudo $0 $@
	exit $?
fi

# Define stuff we need for this script:
export RED='\033[1;31m'
export GREEN='\033[1;32m'
export BLUE='\033[1;34m'
export NC='\033[0m'
export CHECK="\xE2\x9C\x94"
export CROSS="\xE2\x9D\x8C"

# Find out what the most recent version of Emby Server is:
URL=https://github.com$(wget -O - https://github.com/MediaBrowser/Emby.Releases/releases/latest 2>&1 /dev/null | grep "\-deb" | grep "_amd64.deb" |  grep -o '<a href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^<a href=["'"'"']//' -e 's/["'"'"']$//' | head -1)
FILE=$(basename $URL)
VER=${FILE/.deb/}
VER=${VER//[^0-9\.]}
echo "Latest version = ${VER}"

# Get the version of Emby Server that is installed:
CMP=$([[ -f /var/lib/emby/installed.version ]] && cat /var/lib/emby/installed.version)
[[ ! -z "${CMP}" ]] && echo "Installed version = ${CMP}"

# If versions are equal, tell user.  Otherwise, install the newest version:
if [[ "${VER}" == "${CMP}" ]]; then
    echo "${GREEN}NOTICE${NC}: Emby Server is up to date!"
else
    if [[ -z "${VER}" ]]; then
		echo "${GREEN}NOTICE${NC}: Installing Emby Server version ${VER}...."
	else
		echo "${GREEN}NOTICE${NC}: Upgrading Emby Server to version ${VER}....!"
	fi
    wget ${URL} -O /tmp/${FILE}
    apt install -y /tmp/${FILE} && echo ${VER} > /var/lib/emby/installed.version
    rm /tmp/${FILE}    
fi
