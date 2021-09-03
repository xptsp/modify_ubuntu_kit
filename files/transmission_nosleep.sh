#!/bin/sh
# the folder to move completed downloads to port, username, password
SERVER="9091 --auth kodi:xubuntu"

# use transmission-remote to get torrent list from
# transmission-remote list use sed to delete first / last line
# of output, and remove leading spaces use cut to get first
# field from each line
TORRENTLIST=$(transmission-remote $SERVER --list | sed -e '1d;$d;s/^ *//' | cut --only-delimited --delimiter=" " --fields=1)
transmission-remote $SERVER --list

# for each torrent in the list
for TORRENTID in $TORRENTLIST; do
    echo Processing : $TORRENTID

    # check if torrent download is completed
    DL_COMPLETED=$(transmission-remote $SERVER --torrent $TORRENTID --info | grep "Percent Done: " | awk '{print $3}')

    # check torrents current state is
    STATE_STOPPED=$(transmission-remote $SERVER --torrent $TORRENTID --info | grep "State: Seeding\|Stopped\|Finished\|Idle")
    echo $STATE_STOPPED

    # if the torrent is "Stopped", "Finished", or "Idle" after
    # downloading 100%"
    if [ "$DL_COMPLETED" == "0%" ] && [ "$STATE_STOPPED" ]; then
        true
    elif [ "$DL_COMPLETED" == "100%" ] && [ "$STATE_STOPPED" ]; then
        true
	else
        exit 1
    fi
done
