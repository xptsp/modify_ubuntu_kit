#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Sets custom Gnome settings."
	echo ""
	exit 0
fi

#==============================================================================
_title "Adding script to get changed Gnome settings..."
#==============================================================================
FILE=/usr/local/bin/gsettings-diff
cat << EOF > ${FILE}
#!/bin/sh
BEFORE=\`mktemp /tmp/gsettingsXXXXX\`
gsettings list-recursively > \$BEFORE
echo -n "Ok, recorded current settings - now do the change and press enter ..."
read ANS
AFTER=\`mktemp /tmp/gsettingsXXXXX\`
gsettings list-recursively > \$AFTER
diff -u \$BEFORE \$AFTER
rm \$BEFORE \$AFTER
EOF
chmod +x ${FILE}

#==============================================================================
_title "Setting custom Gnome settings..."
#==============================================================================
