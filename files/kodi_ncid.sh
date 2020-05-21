#!/bin/sh

# Send a message to Kodi
# usage: --no-gui --program ncid-kodi


# input is always 8 lines
#
# if input is from a call:
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\n\n
#
# if input is from a message
# input: DATE\nTIME\nNUMBER\nNAME\nLINE\nTYPE\nMESG\n
#
# $TYPE is one of:
#   CID: incoming call
#   OUT: outgoing call
#   HUP: blacklisted hangup
#   MSG: message instead of a call
#   NOT: android text
#   PID: android call
read DATE
read TIME
read NMBR
read NAME
read LINE
read TYPE
read MESG
read MTYPE
[ "$TYPE" != "CID" ] && exit 0

# Abort if any of these conditions are met:
#   (1) no user is running a copy of Kodi at the moment,
#   (2) the Kodi configuration file doesn't exist yet, OR
#   (3) the Kodi webserver is disabled!
home=$(ps aux | grep -e "/usr/bin/kodi" | head -1 | cut -d" " -f 1)
[ ! -f ${home} ] && exit 1
file=${home}/.kodi/userdata/guisettings.xml
[ ! -f ${file} ] && exit 2
enabled=$(cat $file | grep "services.webserver\"" | cut -d">" -f 2 | cut -d"<" -f 1)
[ "$enabled" == "false" ] && exit 3

# Get user credentials for local Kodi instance:
user=$(cat $file | grep "services.webserverusername" | cut -d">" -f 2 | cut -d"<" -f 1)
pass=$(cat $file | grep "services.webserverpassword" | cut -d">" -f 2 | cut -d"<" -f 1)
port=$(cat $file | grep "services.webserverport" | cut -d">" -f 2 | cut -d"<" -f 1)

# Send the notification to the local hosted version of Kodi:
body="{\"jsonrpc\":\"2.0\",\"method\":\"GUI.ShowNotification\",\"params\":{\"title\":\"Call from $NAME\",\"message\":\"$NMBR\",\"displaytime\":5000},\"id\":1}"
/usr/bin/curl -m 5 -X POST -H "Content-Type: application/json" -d "$body" http://$user:$pass@localhost:$port/jsonrpc &
