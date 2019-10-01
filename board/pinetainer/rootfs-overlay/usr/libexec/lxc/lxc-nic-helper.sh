#!/bin/sh

# The ID of the container NIC to set its MAC
readonly NETWORK_ID=0
# The container VLAN configuration file. It
# associates container names with their VLAN
readonly CONTAINER_VLAN_FILE='/etc/lxc/vlan.conf'
# The VLAN to associate the container with if
# none was set in the configuration file
readonly DEFAULT_VLAN=4094

# Assigns a very-likely-unique MAC address to the NETWORK_ID
# NIC of the container this hook is attached to. The generated
# MAC address is the result of a one way function whose parameter
# is the container name.
assignMAC() {
	# Do a cheap hash (IEEE 802.3 Ethernet CRC32) on the container name
	containerNameCrc=$(printf '%s' "$LXC_NAME" | cksum)
	containerNameCrc=${containerNameCrc%% *}

	# Fake two more result bytes by doing ones' complement on the
	# resulting hash
	containerNameCrcExtra=$((containerNameCrc ^ 0xFFFFFFFF))
	containerNameCrcExtra=$((containerNameCrcExtra & 0x0000FFFF))

	# The first two bytes of the MAC address come from the extra
	# bytes. Just make sure that it is a unicast, locally administered
	# MAC (bits xxxxxx10 on the first byte)
	firstTwoMacBytes=$((containerNameCrcExtra & 0xFCFF))
	firstTwoMacBytes=$((firstTwoMacBytes | 0x0200))

	# Finally, combine both byte sources to get the NIC MAC
	mac=$(printf '%04x%08x' $firstTwoMacBytes $containerNameCrc | sed -E '1{s/([0-9a-f][0-9a-f])/&:/g;s/:$//}')

	# Replace the MAC address for the NETWORK_ID NIC. If a MAC
	# was not configured for the NETWORK_ID NIC, then append
	# it to the file
	sed -E -i "/^lxc.net.$NETWORK_ID.hwaddr/{s/=( ?).*/=\1$mac/;h};\${x;/^$/{s//lxc.net.$NETWORK_ID.hwaddr = $mac/;H};x}" "$LXC_CONFIG_FILE"
}

# Configures the bridge the container is connected to with
# the VLAN the container should be in.
connectToVLAN() {
	# Get container's VLAN, or the default one if none found
	containerVlan=$(awk "/^[^#]/ && \$1 == \"$LXC_NAME\" { print \$2; vlanFound=1; exit } END { if (!vlanFound) { print \"$DEFAULT_VLAN\" } }" "$CONTAINER_VLAN_FILE")

	# Change the bridge port configuration so its default VLAN
	# (PVID) for untagged outgoing packets is $containerVlan
	bridge vlan del vid 1 dev "$LXC_NET_PEER" && bridge vlan add vid "$containerVlan" dev "$LXC_NET_PEER" pvid untagged
}

# Decide what to do according to how were we
# called
case $LXC_HOOK_SECTION in
	'net')
		case $LXC_HOOK_TYPE in
			'up')
				connectToVLAN
				exit $?;;
		esac;;
esac
