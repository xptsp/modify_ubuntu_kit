#!/bin/bash
C=/cdrom/casper/filesystem-opt
if [[ -f ${C}.squashfs && -f ${C}.location ]]; then
	D=$(cat ${C}.location)
	cat << EOF >> /etc/fstab
${C}.packed_alt  /${D}       auto  defaults,nofail  0  0
${C}.packed_alt  /rofs/${D}  auto  defaults,nofail  0  0
EOF
fi