#!/bin/bash
# Notes: My personal machine
cat << EOF >> /etc/pulse/default.pa 

load-module module-alsa-sink device=hdmi:0 
load-module module-combine-sink sink_name=combined
set-default-sink combined
EOF
