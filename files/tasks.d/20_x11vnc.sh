#!/bin/bash
[ ! -f /etc/x11vnc.pass ] && x11vnc -storepasswd ${PASSWORD:-"xubuntu"} /etc/x11vnc.pass
