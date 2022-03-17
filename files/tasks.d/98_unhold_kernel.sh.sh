#!/bin/bash
for PACKAGE in $(apt-mark showhold | egrep "linux-(headers|hwe|image|modules)"); do echo apt-mark unhold $PACKAGE; done
exit 0
