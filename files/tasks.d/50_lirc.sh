#!/bin/bash
[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)

# Add $USERNAME to the dialout group:
usermod -aG dialout ${USERNAME}
