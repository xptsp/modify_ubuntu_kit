#!/bin/bash
# Change ownership and permissions:
chown -R htpc:htpc /etc/transmission-daemon/
chown -R htpc:htpc /var/lib/transmission-daemon/
chmod -R 775 /etc/transmission-daemon/
chmod -R 775 /var/lib/transmission-daemon/

# Create necessary folders:
mkdir -p ~htpc/{Downloads,Incomplete}
chown htpc:htpc -R ~htpc/{Downloads,Incomplete}
