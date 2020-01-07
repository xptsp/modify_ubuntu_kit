#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs TimeShift on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing TimeShift..."
#==============================================================================
# First: Install the software :p
#==============================================================================
apt-add-repository -y ppa:teejee2008/ppa
apt install -y timeshift

# Second: Add finisher task to generate a timeshift.json file...
#==============================================================================
[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
cat << EOF > /usr/local/finisher/tasks.d/14_timeshift.sh
#!/bin/bash
# Determine characteristics of root partition:
ROOT_MNT=\$(mount | grep " / ")
ROOT_TYPE=\$([[ "\$(echo \$ROOT_MNT | cut -d" " -f 5)" == "btrfs" ]] && echo "true" || echo "false")
ROOT_DEV=\$(echo \$ROOT_MNT | cut -d" " -f 1)
ROOT_UUID=\$(blkid \$ROOT_DEV -o export | grep "UUID=" | head -1 | cut -d"=" -f 2)

# If we are not dealing with root partition with a BTRFS format, abort this script:
[[ "\$ROOT_TYPE" == "false" ]] && exit 0

# Create the timeshift.json file dynamically:
cat << DONE > /etc/timeshift.json
{
  "backup_device_uuid" : "\${ROOT_UUID}",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "\${ROOT_TYPE}",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "btrfs_use_qgroup" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "false",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "true",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [
    "/root/**",
    "/home/\${USERNAME}/**"
    "/home/htpc/**"
    "/home/img/**"
  ],
  "exclude-apps" : [
  ]
}
DONE
EOF
chmod +x /usr/local/finisher/tasks.d/14_timeshift.sh
