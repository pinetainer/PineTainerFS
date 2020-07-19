#!/bin/sh

# Starts dropbear sshd

start() {
	mkdir -p "$(readlink /etc/dropbear)"

	printf 'Starting dropbear: '

	umask 077

	if \
	start-stop-daemon -S -q -p /var/run/dropbear.pid \
	--exec /usr/sbin/dropbear -- -R -B -E
	then
		if ping -c 1 -q 192.168.0.30 > /dev/null 2>&1; then
			# If the daemon was started and we have connectivity with the command
			# computer, turn on a LED
			echo 'activity' > /sys/class/leds/pine-h64:green:heartbeat/trigger
			echo 'OK'
		else
			# Otherwise, turn on another LED, signaling possible failure
			echo 'pattern' > /sys/class/leds/pine-h64:blue:status/trigger
			echo '255 2500 0 5000' > /sys/class/leds/pine-h64:blue:status/pattern
			echo 'FAIL'
			start-stop-daemon -K -q -p /var/run/dropbear.pid > /dev/null 2>&1 || true
		fi
	else
		echo 'FAIL'
	fi
}

stop() {
	printf 'Stopping dropbear: '

	if start-stop-daemon -K -q -p /var/run/dropbear.pid; then
		echo 'none' > /sys/class/leds/pine-h64:green:heartbeat/trigger
		echo 'none' > /sys/class/leds/pine-h64:blue:status/trigger
		echo 'OK'
	else
		echo 'FAIL'
	fi
}

restart() {
	stop
	start
}

case "$1" in
	start)			start;;
	stop)			stop;;
	restart|reload)	restart;;
	*)				echo "Usage: $0 {start|stop|restart}"
					exit 1
esac
