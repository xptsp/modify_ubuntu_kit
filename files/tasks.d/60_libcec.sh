#!/bin/bash
[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)
usermod -aG dialout ${USERNAME}
usermod -aG dialout htpc
