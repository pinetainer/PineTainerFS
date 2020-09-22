#!/bin/sh

start() {
	printf 'Starting inadyn: '

	if start-stop-daemon -p /run/inadyn.pid -x /usr/sbin/inadyn -c inadyn -k 077 -o -q -S; then
		echo 'OK'
	else
		exit_code=$?
		echo 'FAIL'
		return $exit_code
	fi
}

stop() {
	printf 'Stopping inadyn: '

	if start-stop-daemon -p /run/inadyn.pid -x /usr/sbin/inadyn -o -q -K; then
		echo 'OK'
	else
		exit_code=$?
		echo 'FAIL'
		return $exit_code
	fi
}

restart() {
	stop && start
}

case "$1" in
	start)			start;;
	stop)			stop;;
	restart|reload)	restart;;
	*)				echo "Usage: $0 {start|stop|restart}"
					exit 1
esac
