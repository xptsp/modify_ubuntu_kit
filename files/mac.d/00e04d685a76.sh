#!/bin/bash
# Notes: My personal machine
cat << EOF >> /etc/pulse/default.pa 

load-module module-alsa-sink device=hw:0,7 
load-module module-combine-sink sink_name=combined
set-default-sink combined
EOF
