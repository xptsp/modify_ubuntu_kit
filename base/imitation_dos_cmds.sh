#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Imitation DOS commands on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Creating the imitation DOS commands..."
#==============================================================================
DST=/usr/local/bin
ln -sf /bin/cp ${DST}/copy
ln -sf /bin/mv ${DST}/move
ln -sf /bin/mv ${DST}/ren
ln -sf /bin/mkdir ${DST}/md
ln -sf /bin/rmdir ${DST}/rd
ln -sf /bin/rm ${DST}/del
ln -sf /bin/cat ${DST}/list
ln -sf /bin/nano ${DST}/edit
ln -sf /sbin/ifconfig ${DST}/ipconfig
ln -sf /usr/bin/clear ${DST}/cls
