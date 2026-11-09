#!/bin/bash

set ${SET_X:+-x} -eou pipefail

echo "::group:: ===$(basename "$0")==="

# copy system files
rsync -rvK /ctx/etc /
rsync -rvK /ctx/usr /

/ctx/server-packages.sh

/ctx/branding.sh

/ctx/desktop-changes.sh

/ctx/fetch-quadlets.sh

/ctx/base-image-changes.sh

mkdir -p /usr/lib/bootc/kargs.d
echo 'kargs = ["rd.neednet=1"]' > /usr/lib/bootc/kargs.d/01-clevis-net.toml

mkdir -p /usr/lib/dracut/dracut.conf.d
echo 'add_dracutmodules+=" ostree network clevis "' > /usr/lib/dracut/dracut.conf.d/clevis.conf

/ctx/cleanup.sh

echo "::endgroup::"
