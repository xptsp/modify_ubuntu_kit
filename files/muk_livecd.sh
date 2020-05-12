#!/bin/bash
C=/cdrom/casper/filesystem-opt
if [[ -f ${C}.squashfs && -f ${C}.location ]]; then
	mount ${C}.packed_alt /$(cat ${C}.location)
	mount ${C}.packed_alt /rofl/$(cat ${C}.location)
fi
