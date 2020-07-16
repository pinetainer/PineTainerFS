#!/bin/sh

# Installs firmware blobs needed to fully utilize all the Pine H64 hardware.
# This script should be run as root.

for blob in blobs/rtl_bt/* blobs/rtlwifi/*; do
	blob="${blob#?*/}"
	if install -D -g 0 -m 0644 "blobs/$blob" "/lib/firmware/$blob"; then
		printf '> Installed %s to %s.\n' "$blob" "/lib/firmware/$blob"
	else
		printf '\033[1;91;40m! An error occurred while installing %s. Are you root?\n' "$blob" >&2
		exit 1
	fi
done
