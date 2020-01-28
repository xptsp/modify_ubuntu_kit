#!/bin/bash
[[ -f /usr/local/settings/finisher.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

### Second: Get the non-USB ethernet adapter's MAC address:
ETHERNET=$(lshw -c network -disable usb -short | grep -i "ethernet")
IFS=" " read -ra ETH_NAME <<< $ETHERNET
export ETH_NAME=${ETH_NAME[1]}
MAC_ADDR=$(ip address show $ETH_NAME | grep "ether" | cut -d" " -f 6)

### Third: Create if necessary, then change to the finisher folder:
[ ! -d /usr/local/finisher/ ] && mkdir -p /usr/local/finisher/

### Fourth: Attempt to get machine-specific task from DropBox:
### NOTE: 62^15 = 7.689097049487666e+26 possible matches.  Collision improbable.....
### Combine hashed MAC address with this array to get the DropBox referrer:
j=0
PHRASE=()
DID=$1
if [[ "$1" != "$(echo $1 | cut -d"/" -f1)" ]]; then
	if [[ ! $1 =~ http* ]]; then
		echo "Requires DropBox ID!"
		exit 1
	fi
	DID=$(echo $DID | cut -d"/" -f 5)
fi
echo "Using Dropbox Phrase: $DID"
echo "Using MAC Address:    $MAC_ADDR"
MAC_HASH=$(echo $MAC_ADDR | md5sum)
for (( i=0; i<${#DID}; i++ )); do
        n_MAC=$(ord ${MAC_HASH:$i:1})
        n_DID=$(ord ${DID:$i:1})
        let "j=$n_MAC+$n_DID"
        PHRASE+=($j)
done
_title "Adding Generated Phrase: ${PHRASE[@]}"
[[ -f /usr/local/finisher/phrase.list ]] && sed -i "/$(echo ${PHRASE[@]})/d" /usr/local/finisher/phrase.list
echo ${PHRASE[@]} >> /usr/local/finisher/phrase.list
