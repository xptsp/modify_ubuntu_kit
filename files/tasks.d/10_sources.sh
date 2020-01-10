#!/bin/bash
[[ ! -f /etc/apt/sources.list.orig ]] && cp /etc/apt/sources.list /etc/apt/sources.list.orig
[[ -f /etc/apt/sources.list.new ]]  && cp /etc/apt/sources.list.new /etc/apt/sources.list
