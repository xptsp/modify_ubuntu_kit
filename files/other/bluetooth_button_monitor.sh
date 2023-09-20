#!/bin/bash

# Bluetooth speaker/headphone button monitor

urlencode() {
	# urlencode <string>

	old_lc_collate=$LC_COLLATE
	LC_COLLATE=C

	local length="${#1}"
	for (( i = 0; i < length; i++ )); do
		local c="${1:$i:1}"
		case $c in
			[a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
			*) printf '%%%02X' "'$c" ;;
		esac
	done

	LC_COLLATE=$old_lc_collate
}

google_tts() {
	# google_tts <string>
	wget --quiet -O - -U "stream-mp3/mpg123/0.59r" \
		'http://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q='$(urlencode "$@")'&tl=en' |  madplay -Q -o wave:- -
}

_paplay() {
	[[ -z $1 || -f $1 ]] && paplay $1
}

# Select Text To Speech Engine
TTS_ENGINE="google_tts"

while true
do
	# If result is empty, bluetooth device is not connected. Wait for new
	# input device and try again
	while [ ! -e /dev/input/event0 ]
	do
		if [ ! -d /dev/input ]; then
			inotifywait -qqe create /dev
		else
			inotifywait -qqe create /dev/input
		fi
	done

	# Parse the output of the Bluetooth speaker/headphone buttonlogger
	# program and output voice and control mpd accordingly.
	BUTTON=$(/usr/local/bin/buttonlogger /dev/input/event0)
	case $BUTTON in
		PLAY)
		  _paplay /usr/local/share/voices/play-track.wav
		  mpc -q play
		  ;;
		START)
		  _paplay /usr/local/share/voices/play-track.wav
		  mpc -q play
		  ;;
		PAUSE)
	 	  CURRENT_SONG="$(mpc current | sed -e 's|["'\'']||g')"
		  mpc -q pause
		  _paplay /usr/local/share/voices/pause-track.wav
		  [[ $(grep -c wlan0-1 /proc/net/wireless) -eq 1 ]] && $TTS_ENGINE "$CURRENT_SONG" | _paplay
		  ;;
		NEXT)
		  mpc -q pause
		  _paplay /usr/local/share/voices/next-track.wav
		  mpc -q next
		  ;;
		PREVIOUS)
		  mpc -q pause
		  _paplay /usr/local/share/voices/previous-track.wav
		  mpc -q prev
		  ;;
	esac
done
