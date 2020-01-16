#!/bin/bash
# Determine where the toolkit is installed:
[[ -e /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e "${MUK_DIR}" ]] && exit 0

# Update the toolkit, then copy to the target install:
rm -rf /target/${MUK_DIR}
mkdir -p /target/${MUK_DIR}
cp -R ${MUK_DIR}/* /target/${MUK_DIR}/
pushd /target/${MUK_DIR}/
git pull
popd

# Copy the phrase.list from the install source to the target install:
[[ -f /cdrom/casper/phrase.list ]] && cp --update /cdrom/casper/phrase.list /target/usr/local/finisher/phrase.list

# Execute the finisher inside a chroot inside target install:
(chroot /target ${MUK_DIR}/files/finisher.sh) 1> /target/usr/local/finisher/finisher.log 2>&1

exit 0
