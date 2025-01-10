#!/bin/bash
# Get details about root filesystem:
ROOT_SYS=$(mount | grep " / " | cut -d" " -f 1)
echo "Root Partition      = ${ROOT_SYS}"
ROOT_TYPE=$(blkid ${ROOT_SYS} --output export | sed -n 's/^TYPE=//p')
echo "Root Partition Type = ${ROOT_TYPE}"

# If root filesystem is btrfs, then create snapshot of system immediately after installation:
[[ "${ROOT_TYPE}" == "btrfs" ]] && timeshift --create --comments "After Installation"
