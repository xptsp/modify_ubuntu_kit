#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Adds GRUB script for Recovery Partition."
	echo ""
	exit 0
fi

#==============================================================================
_title "Adding GRUB script for Recovery Partition"
#==============================================================================
cat << EONF > /etc/grub.d/50_recovery
#!/bin/sh
DEV=$(blkid | grep "Recovery" | cut -d: -f 1)
if [ -z "\$DEV" ]; then
	echo "\$(gettext_printf "No GRUB entry added for recovery partition because no recovery partition found.")" >&2
	exit 0
fi
UUID=$(blkid -o export $DEV | grep "^UUID=" | cut -d= -f 2)
if [ -z "\$UUID" ]; then
	echo "\$(gettext_printf "No GRUB entry added for recovery partition because no recovery partition found.")" >&2
	exit 0
fi

echo "Adding boot menu entry for Recovery Partition..." >&2
cat << EOF
menuentry "Recovery Partition Boot Menu" {
	insmod part_msdos
	insmod ntfs
	set root='hd0,msdos4'
	if [ x\$feature_platform_search_hint = xy ]; then
	search --no-floppy --fs-uuid --set=root --hint-bios=hd0,msdos4 --hint-efi=hd0,msdos4 --hint-baremetal=ahci0,msdos4 \$UUID
	else
		search --no-floppy --fs-uuid --set=root \$UUID
	fi
	set gfxpayload=keep
	linux   /casper/vmlinuz boot=casper file=/cdrom/preseed/ubuntu.seed maybe-ubiquity quiet splash --- 
	initrd  /casper/initrd
}
EOF
EONF
chmod +x /etc/grub.d/50_recovery
