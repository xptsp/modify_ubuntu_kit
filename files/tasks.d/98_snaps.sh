#!/bin/bash

# Install any snaps and ack files found in "/var/lib/snapd/snaps.new": 
for FILE in /var/lib/snapd/snaps.new/*.snap; do 
	snap ack ${FILE/snap/assert}
	snap install ${FILE}
done
