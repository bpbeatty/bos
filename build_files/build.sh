#!/bin/bash

set ${SET_X:+-x} -eou pipefail

echo "::group:: ===$(basename "$0")==="

# copy system files
rsync -rvK /ctx/etc /
rsync -rvK /ctx/usr /

/ctx/remove-cliwrap.sh

/ctx/branding.sh

/ctx/signing.sh

/ctx/composefs.sh

/ctx/server-packages.sh

/ctx/desktop-changes.sh

/ctx/fetch-quadlets.sh

/ctx/base-image-changes.sh

#### Example for enabling a System Unit File

# systemctl enable podman.socket
systemctl enable remote-fs.target

echo "::endgroup::"
