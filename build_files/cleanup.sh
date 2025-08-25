#!/usr/bin/bash
#shellcheck disable=SC2115

set ${SET_X:+-x} -eou pipefail

echo "::group:: ===$(basename "$0")==="

repos=(
    charm
    docker-ce
    fedora-cisco-openh264
    fedora-updates
    fedora-updates-archive
    fedora-updates-testing
    gh-cli
    google-chrome
    negativo17-fedora-multimedia
    negativo17-fedora-nvidia
    nvidia-container-toolkit
    rpm-fusion-nonfree-nvidia-driver
    rpm-fusion-nonfree-steam
    tailscale
    terra
    ublue-os-packages-fedora-"$(rpm -E %fedora)"
    ublue-os-packages-epel-"$(rpm -E %centos)"
    ublue-os-staging-fedora-"$(rpm -E %fedora)"
    ublue-os-staging-epel-"$(rpm -E %centos)"
    vscode
)

for repo in "${repos[@]}"; do
    if [[ -f "/etc/yum.repos.d/${repo}.repo" ]]; then
        sed -i 's@enabled=1@enabled=0@g' "/etc/yum.repos.d/${repo}.repo"
    fi
done

if [[ ! "${IMAGE}" =~ ucore ]]; then
    coprs=()
    mapfile -t coprs <<<"$(find /etc/yum.repos.d/_copr*.repo)"
    for copr in "${coprs[@]}"; do
        sed -i 's@enabled=1@enabled=0@g' "$copr"
    done
fi

# Cleanup extra directories in /usr/lib/modules
KERNEL_VERSION="$(rpm -q kernel-core --queryformat '%{EVR}.%{ARCH}')"

for kernel_dir in /usr/lib/modules/*; do
    echo "$kernel_dir"
    if [[ "$kernel_dir" != "/usr/lib/modules/$KERNEL_VERSION" ]]; then
        echo "Removing $kernel_dir"
        rm -rf "$kernel_dir"
    fi
done

$DNF clean all

rm -rf /tmp/*
rm -rf /var/*
rm -rf /boot/*
ostree container commit
mkdir -p /tmp
mkdir -p /var/tmp && chmod -R 1777 /var/tmp

