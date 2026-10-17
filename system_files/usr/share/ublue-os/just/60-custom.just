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
