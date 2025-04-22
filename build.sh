#!/usr/bin/env bash
set -e

DOCKER_IMAGE="debian:bookworm"
CONTAINER_NAME="buildroot-tmp"
CONFIG_NAME="buildernet_defconfig"

HOST_DIR="$PWD"
BUILDROOT_DIR="$HOST_DIR/buildroot"
CONFIGS_DIR="$HOST_DIR/configs"
BOARD_DIR="$HOST_DIR/board/buildernet"
ROOTFS_OVERLAY_DIR="$HOST_DIR/rootfs-overlay"
HOST_OUTPUT_DIR="$HOST_DIR/artifacts"

WORKDIR_IN_CONTAINER="/mnt"
INTERNAL_BUILD_DIR="/buildroot-src"

mkdir -p "$HOST_OUTPUT_DIR"

docker pull "$DOCKER_IMAGE"

echo "Running container as $CONTAINER_NAME..."
docker run --rm \
  --name "$CONTAINER_NAME" \
  -v "$HOST_DIR":"$WORKDIR_IN_CONTAINER":rw \
  -w "$WORKDIR_IN_CONTAINER" \
  -e FORCE_UNSAFE_CONFIGURE=1 \
  "$DOCKER_IMAGE" \
  bash -c "
    apt-get update && apt-get install -y \
      build-essential git bc curl bzip2 cpio unzip \
      python3 rsync file libncurses-dev wget libelf-dev libssl-dev

    rm -rf $INTERNAL_BUILD_DIR
    mkdir -p $INTERNAL_BUILD_DIR
    cp -R $WORKDIR_IN_CONTAINER/buildroot/* $INTERNAL_BUILD_DIR/
    cp $WORKDIR_IN_CONTAINER/configs/$CONFIG_NAME $INTERNAL_BUILD_DIR/configs/
    mkdir -p $INTERNAL_BUILD_DIR/rootfs-overlay
    cp -a $WORKDIR_IN_CONTAINER/rootfs-overlay/* $INTERNAL_BUILD_DIR/rootfs-overlay/
    mkdir -p $INTERNAL_BUILD_DIR/board/buildernet
    cp -a $WORKDIR_IN_CONTAINER/board/buildernet/* $INTERNAL_BUILD_DIR/board/buildernet/

    cd $INTERNAL_BUILD_DIR
    make $CONFIG_NAME
    make

    mkdir -p $WORKDIR_IN_CONTAINER/artifacts
    cp output/images/* $WORKDIR_IN_CONTAINER/artifacts/
  "

echo "✅ Build complete. Artifacts available in: $HOST_OUTPUT_DIR"

