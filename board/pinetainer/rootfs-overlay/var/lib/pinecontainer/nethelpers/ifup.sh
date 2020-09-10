#!/bin/sh

# Configures a TAP interface for a Pinecontainer.
# This script is called by QEMU.
# Parameters:
# $1: the TAP interface created by QEMU.

# Remove path components, extension and prefixes from the script name
script_name="${0##*/}"
script_name="${script_name%%.*}"
script_name_suffixes="${script_name#*-*-}"

# Extract the bridge device and VLAN number from the suffixes
bridge_dev="${script_name_suffixes%%-*}"
vlan="${script_name_suffixes#*-}"
vlan="${vlan#vlan}"

# The TAP device is already set up by QEMU. Just put it on the
# bridge device, which we assume it is already set up, and configure
# that access port in the appropriate VLAN
ip link set "$1" master "$bridge_dev" && \
bridge vlan add vid "$vlan" dev "$1" pvid untagged && \
default_pvid=$(cat "/sys/class/net/$bridge_dev/bridge/default_pvid") && \
if [ "$vlan" != "$default_pvid" ]; then
	bridge vlan del vid "$default_pvid" dev "$1"
fi && \
ip link set "$1" up
