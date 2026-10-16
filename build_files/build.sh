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

# rebuild static initramfs for the embedded kernel (if Clevis/modules changed)
KVER=$(ls /usr/lib/modules 2>/dev/null | head -n1 || true)
if [[ -n "$KVER" ]]; then
    echo "::group::Regenerating static initramfs for kernel $KVER"
    dracut --force --kver "$KVER"
    echo "::endgroup::"
fi

# systemctl enable podman.socket
systemctl enable remote-fs.target

echo "::endgroup::"
