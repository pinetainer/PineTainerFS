#!/bin/sh

# Establishes a minimal network configuration with a static IP address
# and gateway, using iptables to restrict communications to the
# administration computer and the Internet only.

readonly NETWORK_IFACE=eth0

case "$1" in
	start)			printf 'Configuring network: '
					if iptables -P INPUT DROP && \
					iptables -A INPUT -s 192.168.0.30 -j ACCEPT && \
					iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT && \
					iptables -P OUTPUT DROP && \
					iptables -A OUTPUT -d 192.168.0.30 -j ACCEPT && \
					iptables -A OUTPUT ! -d 192.168.0.0/27 -j ACCEPT && \
					ip addr add 192.168.0.29/27 dev "$NETWORK_IFACE" && \
					ip link set "$NETWORK_IFACE" up
					then
						# Give the network adapter a bit of time to stabilise
						for tick in 1 2 3 4 5 6; do
							if [ "$((tick % 2))" -eq 0 ]; then
								printf '.'
							fi
							sleep 1
						done

						if ip route add default via 192.168.0.1 dev "$NETWORK_IFACE"; then
							echo ' OK'
						else
							echo ' ERROR'
						fi
					else
						echo 'ERROR'
					fi;;

	stop)			printf 'Stopping network: '
					if iptables -P INPUT ACCEPT && \
					iptables -F INPUT && \
					iptables -P OUTPUT ACCEPT && \
					iptables -F OUTPUT && \
					ip addr del 192.168.0.29/27 dev "$NETWORK_IFACE" && \
					ip link set "$NETWORK_IFACE" down
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
