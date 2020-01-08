#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Creates development workspace after boot."
	echo ""
	exit 0
fi

#==============================================================================
_title "Adding script to creates development workspace after boot...."
#==============================================================================
[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
cat << EOF > /usr/local/finisher/tasks.d/13_workspace.sh
#!/bin/bash
# Create the directories we need:
[[ ! -d /home/img/edit ]] && mkdir -p /home/img/{edit,original,mnt}
[[ ! -e /img ]] && ln -sf /home/img /img
[[ ! -e /img/extract ]] && ln -sf /img/extract /img/original

# Add lines to "/etc/fstab":
cat /etc/fstab | grep -v "tmpfs" > /tmp/fstab
mv /tmp/fstab /etc/fstab
cat << DONE >> /etc/fstab

# Mount /tmp and /img/edit directory in RAM (tmpfs):
tmpfs  /img/edit  tmpfs  defaults  0  0"
tmpfs  /tmp       tmpfs  defaults  0  0
DONE
EOF
chmod +x /usr/local/finisher/tasks.d/13_workspace.sh
