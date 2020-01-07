#!/bin/bash
#
# this script sets ACPI Wakeup alarm and stops standby if a recording is active
# safe_margin - minutes to start up system before the earliest timer

# bootup system x sec. before timer
safe_margin=60

# modify if different location for tvheadend dvr/log path
cd ~htpc/.hts/tvheadend/dvr/log

######################

start_date=0
stop_date=0

current_date=$(date +%s)

for i in $( ls ); do
    tmp_start=$(cat $i | grep '"start":' | cut -f 2 -d " " | cut -f 1 -d ",")
    tmp_stop=$(cat $i | grep '"stop":' | cut -f 2 -d " " | cut -f 1 -d ",")
#   logger "$0: $i from $(date -d @$tmp_start) to $(date -d @$tmp_stop)"

    start_extra=$(cat $i | grep '"start_extra":' | cut -f 2 -d " " | cut -f 1 -d ",")
    stop_extra=$(cat $i | grep '"stop_extra":' | cut -f 2 -d " " | cut -f 1 -d ",")

    let tmp_start=$tmp_start-$start_extra*60
    let tmp_stop=$tmp_stop+$stop_extra*60
#   logger "$0: $i from $(date -d @$tmp_start) to $(date -d @$tmp_stop)"

    # if recording is active, immediately stop suspend
    # tmp_stop > now and tmp_start < now
    if [ $((tmp_stop)) -gt $((current_date)) -a $((tmp_start)) -lt $((current_date)) ]; then
        name=$(grep -h -A 1 title $i | grep -v  title | sed 's/.*: "\(.*\)"$/\1/')
        logger "$0: Currently RECORDING $name. No Suspend until $(date -d @$tmp_stop!)"
        exit 1;
    fi

    # only check future recordings
    # tmp_stop > now and tmp_start > now
    if [ $((tmp_stop)) -gt $((current_date)) -a $((tmp_start)) -gt $((current_date)) ]; then

        # take lower value (tmp_start or start_date)
        # (start_date = 0) or  (tmp_start < start_date)
        if [ $((start_date)) -eq 0 -o $((tmp_start)) -lt $((start_date)) ]; then
            start_date=$tmp_start
            stop_date=$tmp_stop
            name=$(grep -h -A 1 title $i | grep -v  title | sed 's/.*: "\(.*\)"$/\1/')
        fi
    fi
done

wake_date=$((start_date-safe_margin))

# set up wakeup alarm
if [ $((start_date)) -ne 0 ]; then
    logger "$0: Set Wakealarm for $name to $(date -d @$wake_date)"
    echo 0 > /sys/class/rtc/rtc0/wakealarm
    echo $wake_date > /sys/class/rtc/rtc0/wakealarm
fi
