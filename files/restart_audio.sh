#!/bin/sh
case "${1}" in
    resume|thaw)
        for dev in $(lspci | grep -i "audio" | head -1 | cut -d" " -f 1); do
            echo 1 > /sys/bus/pci/devices/0000:${dev}/remove
        done
        sleep 1
        echo 1 > /sys/bus/pci/rescan
        ;;
esac
