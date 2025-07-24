ARG BASE_IMAGE="bluefin"
ARG TAG_VERSION="gts"
ARG IMAGE="bluefin"
ARG SET_X="x"
ARG VERSION="gts"
ARG DNF="dnf5"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /
COPY cosign.pub /
COPY --from=ghcr.io/bpbeatty/config:latest /rpms /tmp/rpms

# Base Image
FROM ghcr.io/ublue-os/${BASE_IMAGE}:${TAG_VERSION} as base

ARG BASE_IMAGE="bluefin"
ARG IMAGE="bluefin"
ARG SET_X=""
ARG VERSION=""
ARG DNF="dnf5"

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN --mount=type=bind,from=ctx,src=/,dst=/ctx \
    ["/ctx/cleanup.sh"]

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
