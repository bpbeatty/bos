ARG BASE_IMAGE="ghcr.io/ublue-os/bluefin"
ARG TAG_VERSION="stable"

FROM ghcr.io/bpbeatty/config:latest as config
FROM scratch AS ctx
COPY build_files /
COPY system_files /
COPY cosign.pub /

# Base Image
FROM ${BASE_IMAGE}:${TAG_VERSION} as base

ARG BASE_IMAGE="bluefin"
ARG IMAGE="bluefin"
ARG SET_X=""
ARG VERSION="bos"

RUN --mount=type=bind,from=ctx,src=/,target=/ctx \
    --mount=type=bind,from=config,src=/rpms,dst=/tmp/rpms/config \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN --mount=type=bind,from=ctx,src=/,dst=/ctx \
    ["/ctx/cleanup.sh"]

# force dracut to always include network capabilities and clevis
RUN mkdir -p /etc/dracut.conf.d && \
    echo 'add_dracutmodules+=" network clevis "' > /etc/dracut.conf.d/clevis.conf

# run the dracut compilation loop with the /root symlink
RUN KVER=$(ls /usr/lib/modules 2>/dev/null | head -n1 || true) && \
    if [ -n "$KVER" ]; then \
        echo "Applying dracut symlink workaround..." && \
        ORIG_LINK=$(readlink /root) && \
        rm -f /root && mkdir /root && \
        \
        echo "Regenerating static initramfs for kernel $KVER" && \
        dracut --force --kver "$KVER"; \
        DRACUT_STATUS=$?; \
        \
        rm -rf /root && ln -s "$ORIG_LINK" /root && \
        if [ $DRACUT_STATUS -ne 0 ]; then \
            exit $DRACUT_STATUS; \
        fi \
    fi

# inform bootc to append kernel arguments to the physical bootloader
RUN mkdir -p /usr/lib/bootc/kargs.d && \
    echo 'kargs = ["rd.neednet=1"]' > /usr/lib/bootc/kargs.d/01-clevis-net.toml

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
