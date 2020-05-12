#!/bin/bash
C=/cdrom/casper/filesystem-opt
if [[ -f ${C}.packed_alt && -f ${C}.location ]]; then
	mount ${C}.packed_alt /$(cat ${C}.location)
	mount ${C}.packed_alt /rofs/$(cat ${C}.location)
fi
