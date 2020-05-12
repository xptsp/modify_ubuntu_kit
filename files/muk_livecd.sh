#!/bin/bash
C=/cdrom/casper/filesystem-opt
if [[ -f ${C}.squashfs && -f ${C}.location ]]; then
	mount ${C}.squashfs /$(cat ${C}.location)
	mount ${C}.squashfs /rofl/$(cat ${C}.location)
fi
