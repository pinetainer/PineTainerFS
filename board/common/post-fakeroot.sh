#!/bin/sh

# Fixes permissions and ownerships of miscellaneous files in the target filesystem,
# in a more flexible way than with device tables.

# Everything is owned by root
chown -R root:root "${1:?}"
