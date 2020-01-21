#!/bin/bash
# Get details about root filesystem:
ROOT_SYS=$(mount | grep " / ")
ROOT_UUID=$(blkid $(echo $ROOT_SYS | cut -d" " -f 1) | cut -d'"' -f 2)

# If root filesystem is a btrfs, then set up automatic backups:
if [[ "$(echo $ROOT_SYS | cut -d" " -f 5)" == "btrfs" ]]; then
	cat < EOF > /etc/cron.d/timeshift-hourly
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=""

0 * * * * root timeshift --check --scripted
EOF
	cat << EOF > /etc/timeshift.json
{
  "backup_device_uuid" : "${ROOT_UUID}",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "true",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "btrfs_use_qgroup" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "false",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [
    "/home/htpc/**",
    "/home/kodi/**"
  ],
  "exclude-apps" : [
  ]
}
EOF
	change_username /etc/timeshift.json
fi
