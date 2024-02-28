#!/bin/bash
[ ! -f /etc/x11vnc.pass ] && x11vnc -storepasswd ${PASSWORD:-"$(grep grep "^ID=" /etc/os-release | cut -d= -f 2)"} /etc/x11vnc.pass
