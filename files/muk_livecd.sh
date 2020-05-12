#!/bin/bash
C=/cdrom/casper/filesystem-opt
[[ -f ${C}.squashfs && -f ${C}.location ]] && cat << EOF >> /etc/fstab
${C}.packed_alt  /$(cat ${C}.location  auto  defaults,nofail  0  0
${C}.packed_alt  /rofs/$(cat ${C}.location  auto  defaults,nofail  0  0
EOF