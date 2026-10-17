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

echo "::endgroup::"
