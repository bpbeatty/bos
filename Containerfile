ARG BASE_IMAGE="bluefin"
ARG IMAGE="bluefin"
ARG TAG_VERSION="gts"

FROM ghcr.io/bpbeatty/config:latest as config
# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /
COPY cosign.pub /

# Base Image
FROM ghcr.io/ublue-os/${BASE_IMAGE}:${TAG_VERSION} as base

ARG BASE_IMAGE="bluefin"
ARG IMAGE="bluefin"
ARG SET_X=""
ARG VERSION=""
ARG DNF="dnf5"

RUN --mount=type=bind,from=ctx,src=/,target=/ctx \
    --mount=type=bind,from=config,src=/rpms,dst=/tmp/rpms/config \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/00-build.sh

RUN --mount=type=bind,from=ctx,src=/,dst=/ctx \
    ["/ctx/cleanup.sh"]

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
