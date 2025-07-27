#!/bin/bash

set -ouex pipefail

# remove
${DNF} remove -y \
  bluefin-backgrounds \
  bluefin-cli-logos \
  bluefin-faces \
  bluefin-fastfetch \
  bluefin-logos \
  bluefin-schemas \
  gnome-shell-extension-tailscale-gnome-qs \
  tailscale \
  ublue-bling \
  ublue-brew \
  ublue-fastfetch \
  ublue-motd \
  ublue-os-signing
  # bluefin-plymouth \

# install
${DNF} install -y clevis clevis-dracut clevis-udisks2 firefox firefox-langpacks \
  vim gqrx # fedora-logos

${DNF} install -y /tmp/rpms/config/bpbeatty-signing*.rpm

# swap
${DNF} swap -y nano-default-editor vim-default-editor

echo "::group:: ===Remove CLI Wrap==="
/ctx/01-remove-cliwrap.sh
echo "::endgroup::"

echo "::group:: ===Branding Changes==="
/ctx/02-branding.sh
echo "::endgroup::"

echo "::group:: ===Base Image Changes==="
/ctx/07-base-image-changes.sh
echo "::endgroup::"

echo "::group:: ===Container Signing==="
/ctx/signing.sh
echo "::endgroup::"

#### Example for enabling a System Unit File

# systemctl enable podman.socket
