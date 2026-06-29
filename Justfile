set unstable

mod? titanoboa

# Constants

repo_image_name := lowercase("bos")
repo_name := lowercase("bpbeatty")
IMAGE_REGISTRY := "ghcr.io" / repo_name
FQ_IMAGE_NAME := IMAGE_REGISTRY / repo_image_name

# Images

[private]
images := '(

    # Stable Images
    [bazzite-gnome]=' + bazzite_gnome + '
    [bluefin]=' + bluefin + '
    [bluefin-dx]=' + bluefin_dx + '
    [bluefin-nvidia]=' + bluefin_nvidia + '
    [bluefin-dx-nvidia]=' + bluefin_dx_nvidia + '

)'

# Build Containers

[private]
chunkah := shell('yq -r ".images[] | select(.name == \"$2\") | \"\\(.image):\\(.tag)\"" $1', image-file, "chunkah")
[private]
qemu := shell('yq -r ".images[] | select(.name == \"$2\") | \"\\(.image):\\(.tag)@\\(.digest)\"" $1', image-file, "qemu")

# Base Containers

[private]
bazzite_gnome := shell('yq -r ".images[] | select(.name == \"$2\") | \"\\(.image):\\(.tag)@\\(.digest)\"" $1', image-file, "bazzite-gnome")
[private]
bluefin := shell('yq -r ".images[] | select(.name == \"$2\") | \"\\(.image):\\(.tag)@\\(.digest)\"" $1', image-file, "bluefin")
[private]
bluefin_nvidia := shell('yq -r ".images[] | select(.name == \"$2\") | \"\\(.image):\\(.tag)@\\(.digest)\"" $1', image-file, "bluefin-nvidia")
[private]
bluefin_dx := shell('yq -r ".images[] | select(.name == \"$2\") | \"\\(.image):\\(.tag)@\\(.digest)\"" $1', image-file, "bluefin-dx")
[private]
bluefin_dx_nvidia := shell('yq -r ".images[] | select(.name == \"$2\") | \"\\(.image):\\(.tag)@\\(.digest)\"" $1', image-file, "bluefin-dx-nvidia")

[private]
default:
    @{{ just }} --list

# Check Just Syntax
[group('Just')]
check:
    {{ just }} --unstable --fmt --check

# Fix Just Syntax
[group('Just')]
fix:
    {{ just }} --unstable --fmt

# Cleanup
[group('Utility')]
clean:
    find {{ repo_image_name }}_* -maxdepth 0 -exec rm -rf {} \; 2>/dev/null || true
    rm -f output*.env changelog*.md version.txt previous.manifest.json
    rm -f ./*.sbom.*

# Build
[group('Image')]
build image="bluefin": (build-image image) (secureboot "localhost" / repo_image_name + ":" + image) (rechunk image)

# Build Image
[group('Image')]
build-image image="bluefin":
    #!/usr/bin/bash
    {{ ci_grouping }}
    {{ verify-container }}
    echo "################################################################################"
    echo "image  := {{ image }}"
    echo "PODMAN := {{ PODMAN }}"
    echo "CI     := {{ CI }}"
    echo "################################################################################"

    declare -A images={{ images }}
    check=${images[{{ image }}]-}
    if [[ -z "$check" ]]; then
        exit 1
    fi

    BUILD_ARGS=({{ if CI != '' { '--cpp-flag=-DGHCI' } else { '' } }})
    mkdir -p {{ GIT_ROOT / BUILD_DIR }}
    BUILDTMP="$(mktemp -d -p {{ GIT_ROOT / BUILD_DIR }})"
    trap 'rm -rf $BUILDTMP' EXIT SIGINT

    set -eoux pipefail

    case "{{ image }}" in
    "bluefin"*) BUILD_ARGS+=("--cpp-flag=-DDESKTOP") ;;
    "bazzite"*) BUILD_ARGS+=("--cpp-flag=-DBAZZITE") ;;
    esac

    # Check Base Container
    verify-container "${check#*-os/}"

    # AKMODS
    {{ if image =~ 'beta' { 'akmods_version=testing' } else if image =~ 'aurora|bluefin|cosmic' { 'akmods_version=stable' } else { '' } }}

    # TODO: should instead take advantage of the kernel version tags on the akmods images to avoid skew between nvidia/zfs and akmods.

    # akmods
    {{ if image =~ 'aurora|bluefin|cosmic' { 'akmods="$(yq -r ".images[] | select(.name == \"akmods-${akmods_version}\")" ' + image-file + ' | yq -r "\"\(.image):\(.tag)@\(.digest)\"")"' } else { '' } }}
    {{ if image =~ 'aurora|bluefin|cosmic' { 'verify-container "${akmods#*-os/}"; BUILD_ARGS+=("--cpp-flag=-DAKMODS=$akmods")' } else { '' } }}

    # zfs
    {{ if image =~ 'cosmic|(aurora.*|bluefin.*)-beta' { 'akmods_zfs="$(yq -r ".images[] | select(.name == \"akmods-zfs-${akmods_version}\")" ' + image-file + ' | yq -r "\"\(.image):\(.tag)@\(.digest)\"")"' } else { '' } }}
    {{ if image =~ 'cosmic|(aurora.*|bluefin.*)-beta' { 'verify-container "${akmods_zfs#*-os/}"; BUILD_ARGS+=("--cpp-flag=-DZFS=$akmods_zfs")' } else { '' } }}

    # nvidia
    {{ if image =~ 'cosmic-nv.*|(aurora-nv.*|bluefin-nv.*)-beta' { 'akmods_nvidia="$(yq -r ".images[] | select(.name == \"akmods-nvidia-open-${akmods_version}\")" ' + image-file + ' | yq -r "\"\(.image):\(.tag)@\(.digest)\"")"' } else { '' } }}
    {{ if image =~ 'cosmic-nv.*|(aurora-nv.*|bluefin-nv.*)-beta' { 'verify-container "${akmods_nvidia#*-os/}"; BUILD_ARGS+=("--cpp-flag=-DNVIDIA=$akmods_nvidia")' } else { '' } }}

    skopeo inspect docker://{{ if image =~ 'cosmic|(aurora.*|bluefin.*)-beta' { '"${akmods/:*@/@}"' } else { '"${check/:*@/@}"' } }} > "$BUILDTMP/inspect-{{ image }}.json"

    # Get The Version
    fedora_version="$(jq -r '.Labels["ostree.linux"]' < "$BUILDTMP/inspect-{{ image }}.json" | grep -oP 'fc\K[0-9]+')"
    VERSION="{{ image }}-${fedora_version}.$(date +%Y%m%d)"
    skopeo list-tags docker://{{ FQ_IMAGE_NAME }} > "$BUILDTMP"/repotags.json
    if [[ $(jq "any(.Tags[]; contains(\"$VERSION\"))" < "$BUILDTMP"/repotags.json) == "true" ]]; then
        POINT="1"
        while jq -e "any(.Tags[]; contains(\"$VERSION.$POINT\"))" >/dev/null < "$BUILDTMP"/repotags.json
        do
            (( POINT++ ))
        done
    fi
    if [[ -n "${POINT:-}" ]]; then
        VERSION="${VERSION}.$POINT"
    fi

    # Pull the images
    {{ PODMAN }} pull "$check"
    {{ if image =~ 'cosmic|aurora|bluefin' { PODMAN + ' pull "$akmods"' } else { '' } }}
    {{ if image =~ 'cosmic|(aurora.*|bluefin.*)-beta' { PODMAN + ' pull "$akmods_zfs"' } else { '' } }}
    {{ if image =~ 'cosmic-nv.*|(aurora-nv.*|bluefin-nv.*)-beta' { PODMAN + ' pull "$akmods_nvidia"' } else { '' } }}

    # Labels
    BUILD_ARGS+=(
        "--inherit-labels=false"
        "--label" "org.opencontainers.image.description={{ repo_image_name }} is my OCI image built from ublue projects. It mainly extends them for my uses."
        "--label" "org.opencontainers.image.source=https://github.com/{{ repo_name }}/{{ repo_image_name }}"
        "--label" "org.opencontainers.image.title={{ repo_image_name }}"
        "--label" "org.opencontainers.image.version=$VERSION"
        "--label" "ostree.kernel_flavor={{ if image =~ 'bazzite' { 'bazzite' } else if image =~ 'beta' { 'coreos-testing' } else { 'coreos-stable' } }}"
        "--label" "ostree.linux=$(jq -r '.Labels["ostree.linux"]' < "$BUILDTMP"/inspect-{{ image }}.json)"
        "--label" "containers.bootc=1"
        "--label" "ostree.bootable=true"
    )

    #Build Args
    BUILD_ARGS+=(
        "--build-arg" "IMAGE={{ image }}"
        "--build-arg" "BASE_IMAGE=${check%%:*}"
        "--build-arg" "TAG_VERSION=${check#*:}"
        "--build-arg" "VERSION=$VERSION"
    )

    {{ if env("GITHUB_TOKEN", "") != "" { 'echo "Adding GitHub Token as build secret..."; BUILD_ARGS+=("--secret" "id=GITHUB_TOKEN,env=GITHUB_TOKEN")' } else { '' } }}

    # Additional Args
    BUILD_ARGS+=(
        "--security-opt" "label=disable"
        "--file" "Containerfile"
        "--tag" "{{ repo_image_name + ":" + image }}"
    )

    {{ PODMAN }} build "${BUILD_ARGS[@]}" {{ GIT_ROOT }}

    {{ if CI != '' { PODMAN + ' rmi -f "${check%@*}"' } else { '' } }}

# Rechunk Image
[group('Image')]
rechunk image="bluefin":
    #!/usr/bin/bash
    {{ shell('mkdir -p $1', GIT_ROOT / BUILD_DIR) }}
    {{ ci_grouping }}
    echo "################################################################################"
    echo "image  := {{ image }}"
    echo "PODMAN := {{ PODMAN }}"
    echo "CI     := {{ CI }}"
    echo "whoami := {{ shell("whoami") }}"
    echo "################################################################################"
    set -eou pipefail
    {{ if CI != '' { 'set -x' } else { '' } }}
    IMG="localhost/{{ repo_image_name + ":" + image }}"
    {{ PODMAN }} image exists "$IMG" || { echo "Image $IMG not found. Please build the image first." >&2; exit 1; }
    TMPDIR="$(mktemp -d -p {{ GIT_ROOT / BUILD_DIR }})"
    trap 'rm -rf "$TMPDIR"' EXIT SIGINT

    {{ PODMAN }} inspect "$IMG" > "$TMPDIR/inspect.json"

    {{ PODMAN }} run --rm \
        --security-opt label=disable \
        --mount=type=bind,source="$TMPDIR/inspect.json",target=/tmp/inspect.json,ro \
        --mount=type=image,source="$IMG",target=/chunkah \
        {{ chunkah }} build \
        {{ if CI != '' { '-v' } else { '' } }} \
            --prune /sysroot/ \
            --max-layers=448 \
            --config /tmp/inspect.json \
        > {{ repo_image_name + "_" + image + ".tar" }}

    {{ PODMAN }} images
    {{ if CI != '' { PODMAN + ' system reset --force' } else { PODMAN + ' rmi -f $IMG' } }}
    {{ skopeo }} copy oci-archive:{{ repo_image_name + "_" + image + ".tar" }} containers-storage:{{ FQ_IMAGE_NAME + ":" + image }} 
    {{ PODMAN }} images

# Build ISO
[group('ISO')]
build-iso image="bluefin":
    {{ shell("mkdir -p $1/output", GIT_ROOT / BUILD_DIR) }}
    {{ SUDOIF }} \
        HOOK_pre_initramfs="{{ if image =~ 'bazzite' { GIT_ROOT / 'iso_files/preinitramfs.sh' } else { '' } }}" \
        HOOK_post_rootfs="{{ GIT_ROOT / 'iso_files/configure_iso.sh' }}" \
        CI="{{ CI }}" \
        {{ just }} titanoboa::build \
        {{ FQ_IMAGE_NAME + ":" + image }} \
        "1" \
        {{ if image =~ "aurora" { GIT_ROOT / "iso_files/kde-flatpaks.txt" } else { GIT_ROOT / "iso_files/gnome-flatpaks.txt" } }} \
        "squashfs" \
        "NONE" \
        {{ FQ_IMAGE_NAME + ":" + image }} \
        "1"
    {{ SUDOIF }} chown "$(id -u):$(id -g)" output.iso
    sha256sum output.iso | tee {{ GIT_ROOT / BUILD_DIR / "output" / repo_image_name + "-" + image + ".iso-CHECKSUM" }}
    mv output.iso {{ GIT_ROOT / BUILD_DIR / "output" / repo_image_name + "-" + image + ".iso" }}
    {{ SUDOIF }} {{ just }} titanoboa::clean

# Run ISO
[group('ISO')]
run-iso image="bluefin":
    {{ if path_exists(GIT_ROOT / BUILD_DIR / "output" / repo_image_name + "-" + image + ".iso") == "true" { '' } else { just + " build-iso " + image } }}
    {{ just }} titanoboa::container-run-vm {{ GIT_ROOT / BUILD_DIR / "output" / repo_image_name + "-" + image + ".iso" }}

# Verify Container with Cosign
[group('Utility')]
verify-container container registry="ghcr.io/ublue-os" key="":
    if ! cosign verify --key "{{ if key == '' { 'https://raw.githubusercontent.com/ublue-os/main/main/cosign.pub' } else { key } }}" "{{ if registry != '' { registry / container } else { container } }}" >/dev/null; then \
        echo "NOTICE: Verification failed. Please ensure your public key is correct." && exit 1 \
    ; fi

# Secureboot Check
[group('Image')]
secureboot image="bluefin":
    #!/usr/bin/bash
    {{ ci_grouping }}
    set -eoux pipefail
    # Get the vmlinuz to check
    kernel_release=$({{ PODMAN }} inspect "{{ image }}" | jq -r '.[].Config.Labels["ostree.linux"]')
    TMP=$({{ PODMAN }} create "{{ image }}" bash)
    TMPDIR="$(mktemp -d -p .)"
    trap 'rm -rf $TMPDIR' EXIT
    {{ PODMAN }} cp "$TMP":/usr/lib/modules/"${kernel_release}"/vmlinuz "$TMPDIR/vmlinuz"
    {{ PODMAN }} rm "$TMP"

    # Get the Public Certificates
    curl --retry 3 -Lo "$TMPDIR"/kernel-sign.der https://github.com/ublue-os/kernel-cache/raw/main/certs/public_key.der
    curl --retry 3 -Lo "$TMPDIR"/akmods.der https://github.com/ublue-os/kernel-cache/raw/main/certs/public_key_2.der
    openssl x509 -in "$TMPDIR"/kernel-sign.der -out "$TMPDIR"/kernel-sign.crt
    openssl x509 -in "$TMPDIR"/akmods.der -out "$TMPDIR"/akmods.crt

    # Make sure we have sbverify
    CMD="$(command -v sbverify)" || true
    if [[ -z "${CMD:-}" ]]; then
        temp_name="sbverify-${RANDOM}"
        {{ PODMAN }} run -dt \
            --entrypoint /bin/sh \
            --security-opt label=disable \
            --workdir {{ GIT_ROOT }} \
            --volume "{{ GIT_ROOT }}/$TMPDIR/:{{ GIT_ROOT }}/$TMPDIR" \
            --name ${temp_name} \
            alpine:edge
        {{ PODMAN }} exec "${temp_name}" apk add sbsigntool
        CMD="{{ PODMAN }} exec ${temp_name} /usr/bin/sbverify"
    fi

    # Confirm that Signatures Are Good
    $CMD --list "$TMPDIR/vmlinuz"
    returncode=0
    if ! $CMD --cert "$TMPDIR/kernel-sign.crt" "$TMPDIR/vmlinuz" ||
       ! $CMD --cert "$TMPDIR/akmods.crt" "$TMPDIR/vmlinuz"; then
        echo "Secureboot Signature Failed...."
        returncode=1
    fi
    if [[ -n "${temp_name:-}" ]]; then
        {{ PODMAN }} rm -f "${temp_name}"
    fi
    exit "$returncode"

# Lint Files
[group('Utility')]
lint:
    # shell
    /usr/bin/find . -iname "*.sh" -type f -not -path "./titanoboa/*" -exec shellcheck "{}" ';'
    # yaml
    yamllint -s {{ justfile_dir() }}
    # just
    {{ just }} check
    # just recipes
    {{ just }} lint-recipes

# Format Files
[group('Utility')]
format:
    # shell
    /usr/bin/find . -iname "*.sh" -type f -exec shfmt --write "{}" ';'
    # yaml
    yamlfmt {{ justfile_dir() }}
    # just
    {{ just }} fix

# Linter Helper
[group('Utility')]
_lint-recipe linter recipe *args:
    #!/usr/bin/bash
    set -eou pipefail
    mkdir -p {{ BUILD_DIR }}
    TMPDIR="$(mktemp -d -p {{ BUILD_DIR }})"
    trap 'rm -rf "$TMPDIR"' EXIT SIGINT
    {{ just }} -n {{ recipe }} {{ args }} 2>&1 | tee "$TMPDIR"/{{ recipe }} >/dev/null
    linter=({{ linter }})
    echo "Linting {{ style('warning') }}{{ recipe }}{{ NORMAL }} with {{ style('command') }}${linter[0]}{{ NORMAL }}"
    {{ linter }} "$TMPDIR"/{{ recipe }} && rm "$TMPDIR"/{{ recipe }} || rm "$TMPDIR"/{{ recipe }}

# Linter Helper
[group('Utility')]
lint-recipes:
    #!/usr/bin/bash
    recipes=(
        build-image
        build-iso
        gen-sbom
        rechunk
        run-iso
        sbom-sign
        secureboot
    )
    for recipe in "${recipes[@]}"; do
        {{ just }} _lint-recipe "shellcheck" "$recipe" bluefin
    done
    recipes=(
        clean
        lint-recipes
    )
    for recipe in "${recipes[@]}"; do
        {{ just }} _lint-recipe "shellcheck" "$recipe"
    done

# Login to GHCR
[group('CI')]
login-to-ghcr $user $token:
    echo "$token" | {{ if PODMAN != "" { PODMAN + ' login ghcr.io -u "$user" --password-stdin' } else { 'docker login ghcr.io -u "$user" --password-stdin' } }}
    {{ if PODMAN != "" { 'echo $token | ' + PODMAN + ' login ghcr.io -u "$user" --password-stdin --authfile ~/.docker/config.json' } else { '' } }}

# Push and Sign
[group('CI')]
push-and-sign image dryrun="true" sign="false":
    #!/usr/bin/bash
    set -eoux pipefail

    {{ shell('mkdir -p $1', BUILD_DIR) }}
    trap 'rm -f {{ BUILD_DIR }}/{digest{,1,2},inspect.json}' EXIT SIGINT
    skopeo inspect oci-archive:{{ repo_image_name }}_{{ image }}.tar > "{{ BUILD_DIR }}/inspect.json"

    for tag in {{ image }} $(jq -r '.Labels["org.opencontainers.image.version"]' < "{{ BUILD_DIR }}/inspect.json"); do
        # Push twice do to bug with annotations not getting pushed on the first time?
        {{ if dryrun == "false" { 'skopeo copy --preserve-digests --digestfile ' + BUILD_DIR + '/digest1 oci-archive:' + repo_image_name + '_' + image + '.tar docker://' + IMAGE_REGISTRY + '/' + repo_image_name + ':$tag >&2' } else { 'echo "$tag" >&2' } }}
        {{ if dryrun == "false" { 'skopeo copy --preserve-digests --digestfile ' + BUILD_DIR + '/digest2 oci-archive:' + repo_image_name + '_' + image + '.tar docker://' + IMAGE_REGISTRY + '/' + repo_image_name + ':$tag >&2' } else { 'echo "$tag" >&2' } }}
    done

    if [[ "{{ dryrun }}" == "true" ]]; then
        echo "Dry run complete. Digests not pushed."
        exit 0
    fi

    # Compare digests are the same, if not fail as something went wrong with the push
    if ! diff {{ BUILD_DIR }}/{digest1,digest2} >/dev/null; then
        echo "Digests are not the same..."
        exit 1
    else
        mv {{ BUILD_DIR }}/digest{1,}
        rm {{ BUILD_DIR }}/digest2
    fi

    # Sign the image with Cosign if enabled
    if [[ "{{ sign }}" == "true" ]]; then
        cosign sign -y --key env://COSIGN_PRIVATE_KEY "{{ IMAGE_REGISTRY + "/" + repo_image_name }}@$(cat {{ BUILD_DIR }}/digest)"
    fi

# Generate SBOM
[group('CI')]
gen-sbom $input $output="":
    #!/usr/bin/bash
    set -eoux pipefail

    # Make SBOM
    if [[ -z "$output" ]]; then
        OUTPUT_PATH="$(mktemp -d)/sbom.json"
    else
        OUTPUT_PATH="$output"
    fi
    syft scan "{{ input }}" -o spdx-json="$OUTPUT_PATH" --select-catalogers "rpm,+sbom-cataloger"

    # Output Path
    echo "$OUTPUT_PATH"

# Add SBOM Signing
[group('CI')]
sbom-sign input $sbom="":
    #!/usr/bin/bash
    set -eoux pipefail

    # set SBOM
    if [[ ! -f "$sbom" ]]; then
        sbom="$({{ just }} gen-sbom {{ input }})"
    fi

    # Sign-blob Args
    SBOM_SIGN_ARGS=(
       "--key" "env://COSIGN_PRIVATE_KEY"
       "--output-signature" "$sbom.sig"
       "$sbom"
    )

    # Sign SBOM
    cosign sign-blob -y "${SBOM_SIGN_ARGS[@]}"

    # Verify-blob Args
    SBOM_VERIFY_ARGS=(
        "--key" "cosign.pub"
        "--signature" "$sbom.sig"
        "$sbom"
    )

    # Verify Signature
    {{ cosign }} verify-blob "${SBOM_VERIFY_ARGS[@]}"

# SBOM Attach (ORAS attach + cosign sign)
[group('CI')]
sbom-attach input $sbom="" $destination="":
    #!/usr/bin/bash
    set -eoux pipefail

    # set SBOM
    if [[ ! -f "$sbom" ]]; then
        sbom="$({{ just }} gen-sbom {{ input }})"
    fi

    : "${destination:={{ IMAGE_REGISTRY }}}"
    TMPDIR="$(mktemp -d -p .)"
    trap 'rm -rf "$TMPDIR"' EXIT SIGINT
    {{ skopeo }} inspect "{{ input }}" > "$TMPDIR/info.json"
    digest="$({{ jq }} -r '.Digest' < "$TMPDIR/info.json")"
    version="$({{ jq }} -r '.Labels["org.opencontainers.image.version"]' < "$TMPDIR/info.json")"

    pushd "$(dirname "$sbom")" > /dev/null
    {{ oras }} attach "$destination/{{ repo_image_name }}@${digest}" "$(basename "$sbom")" --artifact-type application/vnd.spdx+json -a "filename=$(basename "$sbom")" -a "org.opencontainers.image.version=$version"
    sbom_digest="$({{ oras }} discover "$destination/{{ repo_image_name }}@${digest}" --artifact-type application/vnd.spdx+json --format json | {{ jq }} -r '.manifests[0].digest')"
    {{ cosign }} sign -y --key env://COSIGN_PRIVATE_KEY "$destination/{{ repo_image_name }}@${sbom_digest}"
    popd > /dev/null

# Utils

[private]
GIT_ROOT := justfile_dir()
[private]
BUILD_DIR := repo_image_name + "_build"
[private]
just := just_executable() + " -f " + justfile()
[private]
image-file := GIT_ROOT / "image-versions.yml"
[private]
yq := `which yq 2>/dev/null || true`
[private]
jq := `which jq 2>/dev/null || true`
[private]
skopeo := `which skopeo 2>/dev/null || true`
[private]
oras := `which oras 2>/dev/null || true`
[private]
cosign := `which cosign 2>/dev/null || true`
[private]
syft := `which syft 2>/dev/null || true`

# SUDO

[private]
export SUDOIF := if `id -u` == "0" { "" } else { "sudo" }

# Podman By Default

[private]
export PODMAN := if path_exists("/usr/bin/podman") == "true" { env("PODMAN", "/usr/bin/podman") } else if path_exists("/usr/bin/docker") == "true" { env("PODMAN", "docker") } else { env("PODMAN", "exit 1 ; ") }

# Utilities

verify-container := '''
function verify-container() {
    local container="$1"
    local registry="${2:-ghcr.io/ublue-os}"
    local key="${3:-https://raw.githubusercontent.com/ublue-os/main/main/cosign.pub}"
    local target="$registry/$container"
    if ! cosign verify --key "$key" "$target" &>/dev/null; then
        echo "NOTICE: Verification failed. Please ensure your public key is correct." && exit 1
    fi
}
'''
ci_grouping := '
if [[ -n "${CI:-}" ]]; then
    echo "::group::' + style('warning') + '${BASH_SOURCE[0]##*/} step' + NORMAL + '"
    trap "echo ::endgroup::" EXIT
fi'
[private]
CI := env('CI', '')
