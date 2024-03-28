#!/bin/bash
IFACES=($(lshw -c network -disable usb -short 2> /dev/null | grep -i "ethernet" | awk '{print $2}'))
MACS=($(for IFACE in ${IFACES[@]}; do ifconfig ${IFACE} | grep ether | awk '{print $2}' | sed "s|\:||g"; done))
[[ ! -z "${MACS[@]}" ]] && for MAC in ${MACS[@]}; do 
	test -f ${MUK_DIR}/files/mac.d/${MAC}.sh && ${MUK_DIR}/files/mac.d/${MAC}.sh
done
