#!/bin/bash

# Add $USERNAME to the dialout group:
usermod -aG dialout ${USERNAME:-"${USER}"}
