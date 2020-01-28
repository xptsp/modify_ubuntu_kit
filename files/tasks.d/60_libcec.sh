#!/bin/bash
[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)
[[ -z "${PASSWORD}" ]] && PASSWORD=xubuntu

usermod -aG dialout ${USERNAME}
usermod -aG dialout htpc
