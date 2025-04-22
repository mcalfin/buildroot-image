#!/bin/sh
set -e

BOARD_DIR="$(dirname "$0")"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# Create an empty temp directory for genimage rootpath (we use pre-built rootfs.ext4)
ROOTPATH_EMPTY="$(mktemp -d)"
trap 'rm -rf "$ROOTPATH_EMPTY" "$GENIMAGE_TMP"' EXIT

rm -rf "$GENIMAGE_TMP"
echo "Running genimage..."
genimage \
    --rootpath "$ROOTPATH_EMPTY" \
    --tmppath "$GENIMAGE_TMP" \
    --inputpath "$BINARIES_DIR" \
    --outputpath "$BINARIES_DIR" \
    --config "$GENIMAGE_CFG"
