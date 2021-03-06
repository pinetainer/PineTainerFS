#!/bin/bash

# Builds EDK II TianoCore UEFI firmware for PineTainer QEMU "containers" (actually, virtual machines).
# This firmware is compiled in release mode, unlike the pre-built binaries available in https://www.kraxel.org/repos/.
# /bin/bash is required due to bashisms in EDK II edksetup.sh script.
# Based on the following documentation:
# https://github.com/tianocore/tianocore.github.io/wiki/Common-instructions
# https://developer.arm.com/tools-and-software/open-source-software/firmware/edkii-uefi-firmware/building-edkii-firmware
# https://edk2-devel.narkive.com/kig3sDS3/any-patches-for-running-ovmf-on-arm

readonly ROOTFS_OVERLAY_EDK2_IMAGE_PATH='board/pinetainer/rootfs-overlay/usr/share/edk2.git'

# Pads a EDK II QEMU pflash image to 64 MiB, generating a sparse file.
# Parameters:
# $1: the basename of the image file generated by the EDK II build.
# Returns success if the operation was successful, an error code otherwise.
pad_edk2_pflash_image() {
	image_name="${1%%.*}"
	pflash_image_name="$image_name-pflash.raw"
	cp "$WORKSPACE/Build/ArmVirtQemu-AARCH64/RELEASE_GCC5/FV/$1" "$ROOTFS_OVERLAY_EDK2_IMAGE_PATH/$pflash_image_name" && \
	dd if=/dev/null of="$ROOTFS_OVERLAY_EDK2_IMAGE_PATH/$pflash_image_name" obs=64M seek=1 >/dev/null 2>&1
}

while getopts 'sh' option; do
	case $option in
		s)		SKIP_INITIALIZATION=1;;
		h|?|*)	printf 'Syntax: %s [-s]\n' "$0"
				exit 1;;
	esac
done

# Check that the current working directory looks okay
if ! [ -f 'scripts/build-edk2.sh' ]; then
	printf '\033[1mUnexpected current working directory.\n'
	printf '\033[0mPlease change your working directory to the root of the repository.\n'
	exit 1
fi

# Check that the cross-compilation toolchain looks okay
if ! [ -f "$PWD/aarch64-pinechain-linux-musl_sdk-buildroot/bin/aarch64-pinechain-linux-musl-ar" ]; then
	printf '\033[1mThe appropriate cross-compilation toolchain was not found.\n'
	printf '\033[0mPlease install the cross-compilation toolchain that is also used by Buildroot first.\n'
	exit 2
fi

# Environment variables to pass on to the EDK II build system.
export WORKSPACE="$PWD/edk2"
# We reuse the Buildroot cross-compile toolchain
export GCC5_AARCH64_PREFIX="$PWD/aarch64-pinechain-linux-musl_sdk-buildroot/bin/aarch64-pinechain-linux-musl-"
export PACKAGES_PATH="$WORKSPACE/edk2:$WORKSPACE/edk2-platforms"

# Clone relevant repositories
if [ -z "$SKIP_INITIALIZATION" ]; then
	printf '> (Re)creating folder structure...\n' && \
	rm -rf edk2 && \
	mkdir edk2 && \
	printf '> Cloning main edk2 repository...\n' && \
	git clone --recursive https://github.com/tianocore/edk2.git edk2/edk2 && \
	printf '> Cloning edk2 supported platforms repository...\n' && \
	git clone https://github.com/tianocore/edk2-platforms.git edk2/edk2-platforms
fi && (
	# Set up the build environment
	printf '> Setting up build environment...\n' && \
	. edk2/edk2/edksetup.sh && \
	# Build base tools for the host
	printf '> Building BaseTools...\n' && \
	make -C edk2/edk2/BaseTools && \
	# Now build the OVMF for arm64, which actually isn't OVMF because of reasons
	printf '> Building OVMF for AARCH64...\n' && \
	build -a AARCH64 -t GCC5 -p ArmVirtPkg/ArmVirtQemu.dsc -b RELEASE && \
	# QEMU pflash requires at least 64 MiB of data
	printf '> Padding images to 64 MiB in rootfs-overlay...\n' && \
	pad_edk2_pflash_image 'QEMU_EFI.fd' && \
	pad_edk2_pflash_image 'QEMU_VARS.fd' && \
	printf '  Done.\n'
)
