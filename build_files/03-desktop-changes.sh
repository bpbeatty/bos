#!/usr/bin/env bash

set ${SET_X:+-x} -eou pipefail

echo "::group:: ===$(basename "$0")==="

if [[ ${IMAGE} =~ bluefin|bazzite ]]; then
    # ensure /opt and /usr/local are proper
    if [[ ! -h /opt ]]; then
        rm -fr /opt
        mkdir -p /var/opt
        ln -s /var/opt /opt
    fi
    if [[ ! -h /usr/local ]]; then
        rm -fr /usr/local
        ln -s /var/usrlocal /usr/local
    fi

    # Test bluefin gschema override for errors. If there are no errors, proceed with compiling bluefin gschema, which includes setting overrides.
    mkdir -p /tmp/bluefin-schema-test &&
        find /usr/share/glib-2.0/schemas/ -ls -type f ! -name "*.gschema.override" -exec cp {} /tmp/bluefin-schema-test/ \; &&
        echo "Running error test for bos gschema override. Aborting if failed." &&
        # We should ideally refactor this to handle multiple GNOME version schemas better
        glib-compile-schemas --strict /tmp/bluefin-schema-test || exit 1 &&
        echo "Compiling gschema to include bos setting overrides" &&
        glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null
fi

echo "::endgroup::"
