#!/bin/sh
case "${1}" in
    resume|thaw)
        service network-manager restart
	sleep 10
	service vpn restart
		;;
esac
