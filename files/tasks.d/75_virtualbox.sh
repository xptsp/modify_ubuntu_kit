#!/bin/bash
[[ -z "${USERNAME}" ]] && USERNAME=$(id -un 1000)
usermod -aG vboxusers ${USERNAME}
usermod -aG vboxusers htpc
