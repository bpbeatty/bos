# bos

[![Build bos](https://github.com/bpbeatty/bos/actions/workflows/build.yml/badge.svg)](https://github.com/bpbeatty/bos/actions/workflows/build.yml)

These are my customized personal versions of the Universal Blue project. Everything is the `bos` image with different tags.

## Tags

- `bos:bluefin` - bluefin:gts
- `bos:bluefin-dx` - bluefin-dx:gts
- `bos:bluefin-nvidia` - bluefin-nvidia:gts
- `bos:bluefin-dx-nvidia` - bluefin-dx-nvidia:gts

### How to rebase

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/bpbeatty/bos:TAG
```

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/bpbeatty/bos:TAG
```

## Verification

### Image Verification
All images in this repo are signed with sigstore's [`cosign`](https://github.com/sigstore/cosign). You can verify the signatures by running the following command

```console
TAG=bluefin
cosign verify --key "https://raw.githubusercontent.com/bpbeatty/bos/refs/heads/main/cosign.pub" "ghcr.io/bpbeatty/bos:$TAG"
```

## DIY

This repo was built on the [Universal Blue Image Template](https://github.com/ublue-os/image-template) and added to significantly.

That template can be used to extend any image you like, Aurora, Bazzite, Bluefin, uCore or even **bos** so you can make your own ***bos***!

Also, if you just want to tinker, the images built here can be built locally using [`just`](https://just.systems/) and the provided `Justfile`.

```
just build bluefin
```
