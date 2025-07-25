#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y clevis clevis-dracut clevis-udisks2 firefox firefox-langpacks vim gqrx
dnf5 remove -y bluefin-backgrounds bluefin-cli-logos bluefin-faces bluefin-fastfetch bluefin-schemas gnome-shell-extension-tailscale-gnome-qs tailscale ublue-bling ublue-brew ublue-fastfetch ublue-motd
dnf5 swap -y nano-default-editor vim-default-editor


# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

echo "::group:: ===Branding Changes==="
/ctx/01-branding.sh
echo "::endgroup::"

echo "::group:: ===Base Image Changes==="
/ctx/07-base-image-changes.sh
echo "::endgroup::"

echo "::group:: ===Container Signing==="
/ctx/signing.sh
echo "::endgroup::"

#### Example for enabling a System Unit File

# systemctl enable podman.socket
