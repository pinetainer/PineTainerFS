#!/bin/sh

# Establishes a minimal network configuration with a static IP address
# and gateway, using iptables to restrict communications to the
# administration computer and the Internet only.

readonly NETWORK_IFACE=eth0
readonly LAN=192.168.0.0/27
readonly NETWORK_ADDRESS=192.168.0.29/27
readonly CONFIGURATION_HOST_ADDRESS=192.168.0.30
readonly GATEWAY_ADDRESS=192.168.0.1

case "$1" in
	start)			printf 'Configuring network: '
					if nft -f - <<NFT_COMMANDS &&
table ip filter {
	chain input {
		type filter hook input priority filter; policy drop;

		ip saddr $CONFIGURATION_HOST_ADDRESS accept comment "Accept packets from configuration host"
		ct state established accept comment "Accept packets from established connections"
	}

	chain output {
		type filter hook output priority filter; policy drop;

		ip daddr $CONFIGURATION_HOST_ADDRESS accept comment "Allow outgoing packets to the configuration host"
		ip daddr != $LAN accept comment "Allow outgoing packets to the Internet"
	}
}
NFT_COMMANDS
					ip addr add "$NETWORK_ADDRESS" dev "$NETWORK_IFACE" && \
					ip link set "$NETWORK_IFACE" up
					then
						# Give the network adapter a bit of time to stabilize
						for tick in 1 2 3 4 5 6; do
							if [ "$((tick % 2))" -eq 0 ]; then
								printf '.'
							fi
							sleep 1
						done

						if ip route add default via "$GATEWAY_ADDRESS" dev "$NETWORK_IFACE"; then
							echo ' OK'
						else
							echo ' ERROR'
						fi
					else
						echo 'ERROR'
					fi;;

	stop)			printf 'Stopping network: '
					if ip link set "$NETWORK_IFACE" down && \
					ip addr del "$NETWORK_ADDRESS" dev "$NETWORK_IFACE" && \
					nft flush ruleset
					then
						echo 'OK'
					else
						echo 'ERROR'
					fi;;

	restart|reload)	"$0" stop
					"$0" start;;

	*)				echo "Usage: $0 {start|stop|restart}"
  					exit 1
esac
