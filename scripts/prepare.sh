#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
archive=mongodb/mongodb.ce.pi4.r7.0.40.tar.gz
if [[ ! -f "$archive" ]]; then
    curl --fail --location --retry 3 \
        https://github.com/themattman/mongodb-raspberrypi-binaries/releases/download/r7.0.40-rpi-unofficial/mongodb.ce.pi4.r7.0.40.tar.gz \
        --output "$archive"
fi
sha256sum --check checksums.sha256
mkdir -p mongodb/.build
tar --extract --gzip --file "$archive" --directory mongodb/.build mongod mongos
printf '%s\n' 'Build inputs verified and prepared.'
