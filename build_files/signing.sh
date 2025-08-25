#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

echo "::group:: ===$(basename "$0")==="

# Signing
mkdir -p /etc/containers
mkdir -p /etc/pki/containers
mkdir -p /etc/containers/registries.d/

if [ -f /usr/etc/containers/policy.json ]; then
    cp /usr/etc/containers/policy.json /etc/containers/policy.json
fi

cat <<<"$(jq '.transports.docker |=. + {
   "ghcr.io/bpbeatty/bos": [
    {
        "type": "sigstoreSigned",
        "keyPath": "/etc/pki/containers/bos.pub",
        "signedIdentity": {
            "type": "matchRepository"
        }
    }
]}' <"/etc/containers/policy.json")" >"/tmp/policy.json"

cp /tmp/policy.json /etc/containers/policy.json
cp /ctx/cosign.pub /etc/pki/containers/bos.pub
tee /etc/containers/registries.d/bos.yaml <<EOF
docker:
  ghcr.io/bpbeatty/bos:
    use-sigstore-attachments: true
EOF

# seems to be a bootc linting issue here
rm -rf /usr/etc
mkdir -p /usr/etc/containers/
cp /etc/containers/policy.json /usr/etc/containers/policy.json
