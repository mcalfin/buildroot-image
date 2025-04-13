#!/usr/bin/env bash
#
# A script to build inside a Docker container without building directly
# on the host-mounted volume. This avoids macOS permission issues.

set -e

DOCKER_IMAGE="debian:bookworm"
CONTAINER_NAME="buildroot-tmp"
CONFIG_NAME="buildernet_defconfig"
HOST_DIR="$PWD"              # The directory on the host with your source
WORKDIR_IN_CONTAINER="/mnt"  # We'll mount the host directory here, read-only

# Where we'll copy the buildable sources inside the container
INTERNAL_BUILD_DIR="/buildroot-src"

# Where we want final artifacts copied on the host
HOST_OUTPUT_DIR="$HOST_DIR/artifacts"

# 1) Ensure an artifacts directory exists on the host
mkdir -p "$HOST_OUTPUT_DIR"

# 2) Pull the Docker image if not present
docker pull "$DOCKER_IMAGE"

echo "Running container as $CONTAINER_NAME..."
docker run --rm -it \
  --name "$CONTAINER_NAME" \
  -v "$HOST_DIR":"$WORKDIR_IN_CONTAINER":rw \
  -w "$WORKDIR_IN_CONTAINER" \
  -e FORCE_UNSAFE_CONFIGURE=1 \
  "$DOCKER_IMAGE" \
  bash -c "

    # (A) Install build dependencies
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \\
      build-essential git bc curl bzip2 cpio unzip \\
      python3 rsync file libncurses-dev wget libelf-dev libssl-dev

    # (B) Copy the code from /mnt (the host dir) to an internal directory
    # We do NOT build in /mnt, which is the host-mounted volume.
    rm -rf $INTERNAL_BUILD_DIR
    cp -R $WORKDIR_IN_CONTAINER $INTERNAL_BUILD_DIR

    cp /mnt/configs/buildernet_defconfig $INTERNAL_BUILD_DIR/buildroot/configs/

    cp /mnt/rootfs-overlay $INTERNAL_BUILD_DIR/buildroot/rootfs-overlay

    # (C) Build inside the container's own filesystem
    cd $INTERNAL_BUILD_DIR/buildroot

    # Example Buildroot steps:
    make buildernet_defconfig
    make

    # (D) Copy final artifacts (e.g., disk.img) to a known place
    mkdir -p $WORKDIR_IN_CONTAINER/artifacts
    cp output/images/* $WORKDIR_IN_CONTAINER/artifacts/
  "

# After the container exits, the artifacts/disk.img should be in $HOST_OUTPUT_DIR
echo "Build complete. Check $HOST_OUTPUT_DIR for disk.img."

