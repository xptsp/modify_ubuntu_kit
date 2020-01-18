#!/usr/bin/env bash
if [[ "$EUID" -ne 0 ]]; then
	sudo $0
	exit
fi
export RED='\033[1;31m'
export BLUE='\033[1;34m'
export NC='\033[0m'

# Get the FreeVPN account page:
url='https://freevpn.co.uk/accounts/'
html=$( curl -# -L "${url}" 2> '/dev/null' )
if [[ -z ${html} ]]; then
	echo -e "${RED}ERROR:${NC} Cannot get FreeVPN account page from the internet!"
	echo "Make sure you are connected to the internet before trying again!"
	exit 1
fi

# Parse html to get username and password:
username=$(echo ${html} | grep -P -o -e '(<b>Username:</b> (.*?)<\/li>)' | head -n 1 | cut -d">" -f 3 | cut -d"<" -f 1 | cut -d" " -f 2)
password=$(echo ${html} | grep -P -o -e '(<b>Password:</b> (.*?)<\/li>)' | head -n 1 | cut -d">" -f 3 | cut -d"<" -f 1 | cut -d" " -f 2)
if [[ -z ${username} || -z ${password} ]]; then
	echo -e "${RED}ERROR:${NC} Error getting FreeVPN credentials!  Aborting!"
	exit 2
fi
echo -e "${BLUE}Username:${NC} ${username}"
echo -e "${BLUE}Password:${NC} ${password}"
(echo ${username}; echo ${password}) > /etc/openvpn/freevpn/freevpn_creds

# Update certificates if they need to be updated:
[[ -f /etc/openvpn/freevpn/freevpn_last_update ]] && this_update=$(cat /etc/openvpn/freevpn/freevpn_last_update)
echo -e "${BLUE}Current Certificate:${NC} ${this_update:-"N/A"}"
last_update=$(echo ${html} | grep -P -o -e '(Updated ([^<].)*\.)')
echo -e "${BLUE}Certificates Last Updated:${NC} ${last_update}"
if [[ ! "${last_update}" == "${this_update}" ]]; then
	# Get the certificates URL from the accounts page.  Abort at any point if expected result isn't there:
	url=$(echo ${html} | grep -P -o -e '(https://freevpn.me/FreeVPN.me-OpenVPN-Bundle-.*.zip)')
	if [[ -z ${url} ]]; then
		echo -e "${RED}ERROR:${NC} Error getting FreeVPN certificate URL!  Aborting!"
		exit 3
	fi
	base=$(basename ${url})
	wget ${url} -O /tmp/${base} >& /dev/null 2>&1
	if [[ ! -f /tmp/${base} ]]; then
		echo -e "${RED}ERROR:${NC} Error getting FreeVPN certificates from website!  Aborting!"
		exit 4
	fi
	7z x /tmp/${base} -aoa -o/tmp/freevpn.me >& /dev/null 2>&1
	rm /tmp/${base}
	file=$(find /tmp/freevpn.me | grep -e "uk-TCP443")
	echo -e "${BLUE}Using OVPN file:${NC} $(basename "${file}")"
	if [[ ! -f "${file}" ]]; then
		echo -e "${RED}ERROR:${NC} Cannot find required certificate file inside downloaded certificate pack!  Aborting!"
		exit 5
	fi

	# Modify the certificate to meet our needs:
	cat "${file}" | egrep -v "(auth-user-pass|script-security|block-outside-dns)" > /etc/openvpn/freevpn/freevpn.conf
	sed -i "s|;comp-lzo|comp-lzo|g" /etc/openvpn/freevpn/freevpn.conf
	sed -i "s|dev tun|dev vpn_out\ndev-type tun|g" /etc/openvpn/freevpn/freevpn.conf
	cat << EOF >> /etc/openvpn/freevpn/freevpn.conf

#user authorization stuff:
auth-user-pass /etc/openvpn/freevpn/freevpn_creds
auth-nocache
route-noexec

#up and down scripts to be executed when VPN starts or stops
script-security 2
up /etc/openvpn/freevpn/freevpn_iptables.sh
down /etc/openvpn/update-systemd-resolved
down-pre

# prevent DNS leakage
dhcp-option DOMAIN-ROUTE .
EOF
	echo ${last_update} > /etc/openvpn/freevpn/freevpn_last_update
fi
