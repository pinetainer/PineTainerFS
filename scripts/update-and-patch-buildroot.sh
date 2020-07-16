#!/bin/sh

# The directory where the patches to apply to Buildroot are
readonly PATCH_DIR='buildroot-patches'
# The directory where upstream Buildroot is. It matches the
# Buildroot submodule path
readonly UPSTREAM_BUILDROOT_DIR='buildroot'

while getopts 'uych' option; do
	case $option in
		u)		UPDATE_UPSTREAM=1;;
		y)		SKIP_WARNING=1;;
		c)		CLEAN_BUILDROOT_SUBMODULE=1;;
		h|?|*)	printf 'Syntax: %s [-u] [-y] [-c] [-h]\n' "$0"
				exit 1;;
	esac
done

if [ -z "$SKIP_WARNING" ]; then
	printf '\033[1mThis script will discard any local changes made to the Buildroot submodule.\n'
	printf '\033[0mYou can terminate it during the next 5 seconds if that is not okay.\n'
	sleep 5
fi

# First checkout the adequate Buildroot commit
printf '> Updating upstream Buildroot submodule...\n' && \
rm -rf "$UPSTREAM_BUILDROOT_DIR" && \
git submodule init && \
if [ -n "$UPDATE_UPSTREAM" ]; then
	git submodule update --force --remote --merge
else
	git submodule update --force
fi && \

if [ -z "$CLEAN_BUILDROOT_SUBMODULE" ]; then
	# Now apply patches
	for patch_file in "$PATCH_DIR"/*.patch; do
		printf '> Applying patch %s...\n' "$(basename "$patch_file")"
		patch -d "$UPSTREAM_BUILDROOT_DIR" -p 1 < "$patch_file" || exit $?
	done
fi
