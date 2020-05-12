#!/bin/bash
[[ -f /cdrom/casper/filesystem-opt.squashfs ]] && mount /cdrom/casper/filesystem-opt.squashfs /opt/$1
