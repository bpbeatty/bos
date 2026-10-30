# Custom ujust recipes for bpbeatty/bos

[group('Security')]
# Enroll LUKS root partition with Tang server (Usage: ujust enroll-tang nvme0n1p3 http://tang.server:7500)
enroll-tang device tang_url:
    sudo clevis luks bind -d "/dev/{{device}}" tang '{"url": "{{tang_url}}"}'
    echo "Tang binding complete for /dev/{{device}}."

[group('Containers')]
# Launch AMD GPU ROCm PyTorch container test
test-rocm:
    podman run -it --rm \
      --device=/dev/kfd \
      --device=/dev/dri \
      --group-add keep-groups \
      rocm/pytorch:latest \
      python3 -c "import torch; print('ROCm GPU Available:', torch.cuda.is_available())"

# Check for installed Flatpaks that are not listed in the core or DX Brewfiles
check-unlisted-flatpaks:
    #!/usr/bin/bash
    SYS_FILE="/usr/share/ublue-os/homebrew/system-flatpaks.Brewfile"
    DX_FILE="/usr/share/ublue-os/homebrew/system-dx-flatpaks.Brewfile"

    if [ ! -f "$SYS_FILE" ] && [ ! -f "$DX_FILE" ]; then
        echo "Error: Brewfiles not found. Are you running this on the target image?"
        exit 1
    fi

    echo "=== Unlisted Flatpaks currently installed on your system ==="

    # extract application IDs from both Brewfiles into a temporary pattern list
    # This filters out the 'flatpak "' prefix and trailing '"'
    sed -n 's/^flatpak "\(.*\)"/\1/p' "$SYS_FILE" "$DX_FILE" 2>/dev/null > /tmp/listed_flatpaks.txt

    # list all installed application IDs and filter out the listed ones
    # -v excludes matches, -f loads the exclusion patterns from our temp file, -F treats them as fixed strings
    flatpak list --columns=application | grep --invert-match --fixed-strings --file /tmp/listed_flatpaks.txt || echo "All installed Flatpaks are tracked in your Brewfiles!"

    # Clean up
    rm -f /tmp/listed_flatpaks.txt
