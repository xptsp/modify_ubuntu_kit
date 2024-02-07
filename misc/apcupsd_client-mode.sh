#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Install and Configure APCUPSD as network client"
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing APCUPSD..."
#==============================================================================
# First: Install the software:
#==============================================================================
apt install -y apcupsd

#==============================================================================
# Second: Configure the software:
#==============================================================================
FILE=/etc/apcupsd/apcupsd.conf
test -f ${FILE}.bak || sudo cp ${FILE} ${FILE}.bak
sed -i "s|^UPSCABLE .*|UPSCABLE ether|" ${FILE}
sed -i "s|^UPSTYPE .*|UPSTYPE net|" ${FILE}
sed -i "s|^DEVICE .*|DEVICE $(ip route | grep default | awk '{print $3}')|" ${FILE}
sed -i "s|^POLLTIME .*|POLLTIME 10|" ${FILE}
sed -i "s|^BATTERYLEVEL .*|BATTERYLEVEL 10|" ${FILE}
sed -i "s|^MINUTES .*|MINUTES 15|" ${FILE}
sed -i "s|^NETSERVER .*|NETSERVER on|" ${FILE}
sed -i "s|^NISIP .*|NISIP 0.0.0.0|" ${FILE}
sed -i "s|^NISPORT .*|NISPORT 3551|" ${FILE}

#==============================================================================
# Third: Enable and restart the service:
#==============================================================================
sed -i "s|^ISCONFIGURED=.*|ISCONFIGURED=yes|" /etc/default/apcupsd
systemctl restart apcupsd

#==============================================================================
# Fourth: Fix the broadcast message issue:
#==============================================================================
sed -i "s|^WALL=.*|WALL=logger|" /etc/apcupsd/apccontrol

#==============================================================================
_title "Installing Argos Gnome extension and custom APCACCESS script..."
#==============================================================================
# First: Install the Argos extension:
#==============================================================================
git clone https://github.com/bryango/argos /tmp/argos
mv /tmp/argos/argos@pew.worldwidemann.com /usr/share/gnome-shell/extensions/
rm -rf /tmp/argos

#==============================================================================
# Second: Create our custom apcaccess script:
#==============================================================================
DIR=~/.config/argos
mkdir -p ${DIR}
FILE=${DIR}/apcaccess.r.10s+.sh
cat << EOF > 
#!/usr/bin/env bash
LEVEL=\$(apcaccess | grep BCHARGE | awk '{print \$3}')
CHARGING=\$(apcaccess | grep STATUS | grep -q ONLINE || echo "-charging")
LABELS=(missing empty caution low good full)
WHICH=\$(( \${LEVEL/\./} / 200 ))
ICON=battery-\${LABELS[\$WHICH]}\${CHARGING}
echo "APC | iconName=\${ICON}"
echo "---"
apcaccess | while read LINE; do echo "<small>\$LINE</small> | font=monospace"; done
EOF
chmod +x ${FILE}
