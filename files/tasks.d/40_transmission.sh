#!/bin/bash
# Change ownership and permissions:
chown -R vpn:vpn /etc/transmission-daemon/
chown -R vpn:vpn /var/lib/transmission-daemon/
chmod -R 775 /etc/transmission-daemon/
chmod -R 775 /var/lib/transmission-daemon/

# Create necessary folders:
mkdir -p ~vpn/{Downloads,Incomplete}
chown vpn:vpn -R ~vpn/{Downloads,Incomplete}
