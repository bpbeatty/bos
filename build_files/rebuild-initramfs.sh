#!/usr/bin/bash
#shellcheck disable=SC2115

set ${SET_X:+-x} -eou pipefail

echo "::group:: ===$(basename "$0")==="

# Force Dracut to rebuild the initramfs in the correct bootc module path
kver="$(rpm -q kernel-core --queryformat '%{EVR}.%{ARCH}')"
HOME=/root dracut --no-hostonly --force \
    --kver "$kver" --reproducible --zstd -v -f "/usr/lib/modules/$kver/initramfs.img"
chmod 0600 "/usr/lib/modules/$kver/initramfs.img"

echo "::endgroup::"