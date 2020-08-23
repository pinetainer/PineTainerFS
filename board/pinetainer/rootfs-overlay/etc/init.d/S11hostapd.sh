#!/bin/sh

start() {
	printf 'Starting hostapd: '

	if start-stop-daemon -p /run/hostapd.pid -x /usr/sbin/hostapd -c hostapd -k 077 -o -q -S \
	-- -B -P /run/hostapd.pid /etc/hostapd.conf; then
		echo 'OK'
	else
		echo 'FAIL'
	fi
}

stop() {
	printf 'Stopping hostapd: '

	if start-stop-daemon -p /run/hostapd.pid -x /usr/sbin/hostapd -o -q -K; then
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
