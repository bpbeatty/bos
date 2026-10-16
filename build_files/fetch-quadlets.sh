#!/usr/bin/env bash

set ${SET_X:+-x} -euo pipefail

echo "::group:: ===$(basename "$0")==="

USER_TARGETS_DIR="/usr/lib/systemd/user"
mkdir -p "$USER_TARGETS_DIR"

QUADLET_TARGETS=(
    "boxkit-toolbox"
)

for target in "${QUADLET_TARGETS[@]}"; do
    target_file="${USER_TARGETS_DIR}/${target}.target"
    if [[ ! -f "$target_file" ]]; then
        cat > "$target_file" <<EOF
[Unit]
Description=Target for ${target} quadlet
[Install]
WantedBy=default.target
EOF
    fi
done

echo "::endgroup::"
