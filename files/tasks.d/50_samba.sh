#!/bin/bash
(echo ${PASSWORD:-"xubuntu"}; echo ${PASSWORD:-"xubuntu"}) | smbpasswd -a ${USERNAME}
