#!/bin/sh

# Wrapper around make that runs Buildroot with additional
# useful arguments for PineTainer.

# The directory where PineTainerFS resides
readonly PINETAINERFS_DIR="$PWD"

# The directory where Buildroot resides
readonly BUILDROOT_DIR="$PINETAINERFS_DIR/buildroot"

# The directory where build artifacts reside, like
# Buildroot external trees, downloaded files, generated
# images, and so on
readonly BUILD_DIR="$PINETAINERFS_DIR/build"

# Customize download and ccache directories for Buildroot
export BR2_DL_DIR="$BUILD_DIR/download"
export BR2_CCACHE_DIR="$BUILD_DIR/ccache"

# Execute Buildroot Makefile
make -C "$BUILDROOT_DIR" O="$BUILD_DIR" BR2_EXTERNAL="$PINETAINERFS_DIR" "$@"
