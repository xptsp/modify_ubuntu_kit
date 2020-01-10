#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "lirc lirc/dev_input_device select /dev/lirc0" | debconf-set-selections
echo "lirc lirc/transmitter select None" | debconf-set-selections
echo "lirc lirc/serialport select /dev/ttyS0" | debconf-set-selections
echo "lirc lirc/remote select Windows Media Center Transceivers/Remotes (all)" | debconf-set-selections
dpkg-reconfigure -u lirc
