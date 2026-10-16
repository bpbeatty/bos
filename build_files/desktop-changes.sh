#!/usr/bin/env bash

set ${SET_X:+-x} -eou pipefail

echo "::group:: ===$(basename "$0")==="

# Compile gschema overrides and include error checking for invalid overrides
mkdir -p /tmp/ublue-schema-test
find /usr/share/glib-2.0/schemas/ -type f ! -name "*.gschema.override" -exec cp {} /tmp/ublue-schema-test/ \;
cp /usr/share/glib-2.0/schemas/*-bos-modifications.gschema.override /tmp/ublue-schema-test/ || :
echo "Running error test for bos gschema override. Aborting if failed."
glib-compile-schemas --strict /tmp/ublue-schema-test || exit 1
echo "Compiling gschema to include m2os setting overrides"
glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null

echo "::endgroup::"
