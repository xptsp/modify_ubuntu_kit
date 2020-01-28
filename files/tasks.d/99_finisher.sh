#!/bin/bash
# Determine where the toolkit is installed:
[[ -e /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e "${MUK_DIR}" ]] && exit 0

# Update the toolkit, then copy to the target install:
pushd /target/${MUK_DIR}/
git pull
popd

# Copy the phrase.list from the install source to the target install:
[[ -f /cdrom/casper/phrase.list ]] && cp --update /cdrom/casper/phrase.list /target/usr/local/finisher/phrase.list
[[ -f /cdrom/casper/tcmount.ini ]] && cp --update /cdrom/casper/tcmount.ini /target/usr/local/finisher/tcmount.ini
[[ -f /cdrom/casper/settings.conf ]] && cp --update /cdrom/casper/settings.conf /target/usr/local/finisher/settings.conf

# Execute the finisher inside a chroot inside target install:
(chroot /target ${MUK_DIR}/files/finisher.sh) 1> /target/usr/local/finisher/finisher.log 2>&1

exit 0
