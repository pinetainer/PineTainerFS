#!/bin/sh

# Most build scripts invoked by Buildroot don't use the gcc-ar, gcc-ranlib and gcc-nm
# wrappers that add proper LTO support, instead running ar, ranlib and nm directly.
# They also don't register the plugins manually. Therefore, even though Buildroot
# supports generating toolchains with LTO support, that is useless in practice.

# The symptoms of this madness are tons of "undefined reference" linker errors when
# building programs for the target, accompanied by "plugin needed to handle lto object"
# messages printed by ar and ranlib.

# To fix that we replace ar, ranlib and nm with their wrappers in the installed
# toolchain files, which run the underlying binaries with the proper plugins.
# This is hacky, but it works.

readonly BUILDROOT_HOST_BIN_DIR='build/host/bin'
readonly TOOLCHAIN_PREFIX='aarch64-pinechain-linux-musl'

while getopts 'uh' option; do
	case $option in
		u)		UNDO_CHANGES=1;;
		h|?|*)	printf 'Syntax: %s [-u] [-h]\n' "$0"
				exit 1;;
    esac
done

for utility in 'ar' 'ranlib' 'nm'; do
	if [ -z "$UNDO_CHANGES" ] && ! [ -f "$BUILDROOT_HOST_BIN_DIR/$TOOLCHAIN_PREFIX-gcc-$utility" ]; then
		printf '\033[1;91;40m! The script couldn'\''t find a expected symlink. Did Buildroot install the toolchain?\n' >&2
		printf '\033[0m  Run \033[1mmake.sh toolchain-build toolchain-external-build toolchain-external-custom-build\033[0m to install\n' >&2
		exit 2
	fi

	if [ -z "$UNDO_CHANGES" ] && [ -f "$BUILDROOT_HOST_BIN_DIR/$TOOLCHAIN_PREFIX-$utility-nolto" ]; then
		printf '\033[1;91;40m! The toolchain was already fixed.\n' >&2
		exit 3
	fi

	if [ -n "$UNDO_CHANGES" ] && ! [ -f "$BUILDROOT_HOST_BIN_DIR/$TOOLCHAIN_PREFIX-$utility-nolto" ]; then
		printf '\033[1;91;40m! The toolchain was not fixed yet, so there is nothing to undo.\n' >&2
		exit 3
	fi
done

for utility in 'ar' 'ranlib' 'nm'; do
	if [ -z "$UNDO_CHANGES" ]; then
		mv "$BUILDROOT_HOST_BIN_DIR/$TOOLCHAIN_PREFIX-$utility" "$BUILDROOT_HOST_BIN_DIR/$TOOLCHAIN_PREFIX-$utility-nolto" && \
		mv "$BUILDROOT_HOST_BIN_DIR/$TOOLCHAIN_PREFIX-gcc-$utility" "$BUILDROOT_HOST_BIN_DIR/$TOOLCHAIN_PREFIX-$utility"
	else
		mv "$BUILDROOT_HOST_BIN_DIR/$TOOLCHAIN_PREFIX-$utility" "$BUILDROOT_HOST_BIN_DIR/$TOOLCHAIN_PREFIX-gcc-$utility" && \
		mv "$BUILDROOT_HOST_BIN_DIR/$TOOLCHAIN_PREFIX-$utility-nolto" "$BUILDROOT_HOST_BIN_DIR/$TOOLCHAIN_PREFIX-$utility"
	fi || { printf '\033[1;91;40m! An error occurred while moving files.\n' >&2; exit 4; }
done

printf '> Done.\n'
