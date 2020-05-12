#!/bin/bash
C=/cdrom/casper/filesystem-opt
S=${C}.packed_alt
if [[ -f ${S} && -f ${C}.location ]]; then
	D=$(cat ${C}.location)
	cat << EOF >> /etc/fstab
${S}  /${D}       auto  defaults,nofail  0  0
${S}  /rofs/${D}  auto  defaults,nofail  0  0
EOF
fi