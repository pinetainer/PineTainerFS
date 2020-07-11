#!/bin/sh
readonly PINETAINER_ROOT_DIR=/media/almacenamiento/PineH64

# Set download and ccache directories for Buildroot
export BR2_DL_DIR="$PINETAINER_ROOT_DIR/buildroot-dl"
export BR2_CCACHE_DIR="$PINETAINER_ROOT_DIR/buildroot-ccache"

# Extract OS identifier from the first argument
os=$1
shift

# Execute Buildroot makefile
make -C "$PINETAINER_ROOT_DIR/buildroot-$os" $@
