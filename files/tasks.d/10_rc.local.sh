#!/bin/bash
# Deactivate USB and ethernet wakeups from Suspend/Sleep:
# Modified to include Ethernet adapters found on PCI bus...
# Src: https://forums.linuxmint.com/viewtopic.php?p=1281792&sid=cb01aead77138cc42aadd71464bd17ea#p1281792
(/usr/bin/lspci | grep USB; /usr/bin/lspci | grep Ethernet)  | cut -d " " -f 1 > /tmp/t7s1 \
&& cat /proc/acpi/wakeup > /tmp/t7s2 \
&& grep -f /tmp/t7s1 /tmp/t7s2 > /tmp/t7s3 \
&& cat /tmp/t7s3 | cut -c 1-4 > /tmp/t7s4 \
&& sed -i -e 's/^/echo "/' /tmp/t7s4 \
&& sed -i 's/$/" > \/proc\/acpi\/wakeup/' /tmp/t7s4 \
&& (head -n -1 /etc/rc.local; cat /tmp/t7s4; tail -1 /etc/rc.local) > /tmp/rc.local \
&& mv /tmp/rc.local /etc/rc.local \
&& chmod +x /etc/rc.local \
&& rm -f /tmp/t7s1 /tmp/t7s2 /tmp/t7s3 /tmp/t7s4
