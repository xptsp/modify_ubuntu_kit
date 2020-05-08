#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Adds downloadable tasks to the MUK finisher."
	echo ""
	exit 0
fi

#==============================================================================
_title "Adding downloadable tasks to the MUK finisher...."
#==============================================================================
cat << EOF > /usr/local/finisher/phrase.list
212 199 200 156 152 103 177 178 199 153 167 145 218 152 99
166 157 173 169 110 152 167 112 203 160 108 170 157 164 198
219 206 208 213 202 215 154 204 157 197 167 145 166 170 211
EOF
