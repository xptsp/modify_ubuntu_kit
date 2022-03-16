#!/bin/bash
apt-mark unhold linux-headers-5.11.0-27-generic
apt-mark unhold linux-hwe-5.11-headers-5.11.0-27
apt-mark unhold linux-image-5.11.0-27-generic
apt-mark unhold linux-modules-5.11.0-27-generic
apt-mark unhold linux-modules-extra-5.11.0-27-generic
exit 0
