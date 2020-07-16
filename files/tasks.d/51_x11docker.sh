#!/bin/bash
# Setup auto login in LightDM.  Effective next reboot....
cat << DONE > /etc/lightdm/lightdm.conf
[SeatDefaults]
autologin-user=kodi
autologin-user-timeout=0
autologin-session=x11docker-openbox
greeter-session=lightdm-gtk-greeter
allow-guest=false
DONE
# Change user login screen to passwordless login:
usermod -aG nopasswdlogin kodi
