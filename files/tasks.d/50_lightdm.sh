#!/bin/bash
# Setup auto login in LightDM.  Effective next reboot....
cat << DONE > /etc/lightdm/lightdm.conf
[SeatDefaults]
autologin-user=kodi
autologin-user-timeout=0
autologin-session=kodi-openbox
greeter-session=lightdm-gtk-greeter
allow-guest=false
DONE
