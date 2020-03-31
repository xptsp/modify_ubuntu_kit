#!/bin/bash
[[ -f /usr/local/settings/finisher.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

URL=$1
[[ ! -z "$1" ]] && FILE=$(basename ${URL})
DEST=$2

# No parameter specified?  Or maybe help requested?
if [[ -z "$1" || -z "${FILE}" || "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Pull and extract an addon from the Kodi repository."
	echo ""
	echo -e "${RED}Usage:${NC}   ${GREEN}$(basename $0)${NC} ${BLUE}[addon]${NC} ${RED}{dest_dir}${NC}"
	echo -e "${RED}Where:${NC}"
	echo -e "    ${BLUE}[addon]${NC} is the addon to pull from the Kodi repository."
	echo -e "    ${BLUE}{dest_dir}${NC} is the optional destination directory.  Default is kodi addon folder."
	echo ""
	exit 0
fi

# Check the parameters to make sure we got everything:
[ -z "${DEST}" ] && DEST=~/.kodi/addons
[ "${URL}" == "${FILE}" ] && URL=http://mirrors.kodi.tv/addons/leia/${URL}
protocol=$(echo ${URL} | cut -d "/" -f 1)
[[ "${protocol}" != "http:" && "${protocol}" != "https:" ]] && URL=https://${URL}
URL=${URL%/}
DEST=${DEST%/}
EXT=$([[ "$URL" = *.* ]] && echo ".${URL##*.}" || echo '')

# If we don't have an zip extension in parameter 1:
if [[ "$EXT" != "zip" ]]; then
	# Pull the directory listing from the base URL and return error if invalid:
	wget --quiet ${URL}/ -O /tmp/output.txt
	FILE=$(cat /tmp/output.txt | grep "${FILE}" | sed -n 's/.*href="\([^"]*\).*/\1/p' | sort | tail -1)
	rm /tmp/output.txt
	if [ -z "${FILE}" ]; then
		echo -e "${RED}ERROR:${NC} Invalid addon specified!"
		exit 1
	fi
	URL=${URL}/${FILE}

	# Check to see if we already have pulled this version.  If so, notify user:
	NEW_VERSION=$(echo $FILE | cut -d"-" -f 2 | sed "s|.zip||g")
	if [[ -f ${DEST}/${ADDON}/addon.xml ]]; then
		OLD_VERSION=$(cat ${DEST}/${ADDON}/addon.xml | grep -oPm1 "version=\"([\d\.]*)\"" | cut -d "\"" -f 2)
	fi
	if [[ "${NEW_VERSION}" == "${OLD_VERSION}" ]]; then
		echo -e "${GREEN}NOTICE:${NC} Already contains current version of this addon!"
		exit 0
	fi
fi

# Pull the addon and extract it to the destination specified:
wget ${URL} -O /tmp/${FILE} && unzip -o /tmp/${FILE} -d ${DEST}/
[[ -f /tmp/${FILE} ]] && rm /tmp/${FILE}
