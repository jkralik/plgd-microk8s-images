#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
engine="${CONTAINER_ENGINE:-docker}"
registry="${IMAGE_PREFIX:-ghcr.io/jkralik}"
suffix="${VERSION_SUFFIX:--rebuild}"
if ! command -v "$engine" >/dev/null; then
    echo "Container engine not installed: $engine" >&2
    exit 1
fi
if [[ "$(uname -m)" != aarch64 && "$(uname -m)" != arm64 ]]; then
    echo 'Build on native ARM64; smoke-test on a Raspberry Pi 4 before deployment.' >&2
    exit 1
fi
bash scripts/prepare.sh
mongo="$registry/mongodb-bitnami-pi4:7.0.40$suffix"
theme="$registry/keycloak-theme-pi4:0.0.1$suffix"
case "$engine" in
    docker) build=("$engine" build --platform linux/arm64) ;;
    buildah) build=("$engine" bud --platform linux/arm64 --isolation chroot --network host) ;;
    *) echo "Unsupported CONTAINER_ENGINE: $engine (use docker or buildah)" >&2; exit 1 ;;
esac
"${build[@]}" --tag "$mongo" mongodb
"${build[@]}" --build-arg "MONGODB_IMAGE=$mongo" --tag "$theme" keycloak-theme
printf 'Built:\n%s\n%s\n' "$mongo" "$theme"
