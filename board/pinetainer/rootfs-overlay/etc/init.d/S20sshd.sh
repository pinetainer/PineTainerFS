#!/bin/sh

start() {
	printf 'Starting sshd: '

	# Create any missing keys
	/usr/bin/ssh-keygen -A

	if start-stop-daemon -p /run/sshd.pid -x /usr/sbin/sshd -k 077 -o -q -S; then
		echo 'OK'
	else
		exit_code=$?
		echo 'FAIL'
		return $exit_code
	fi
}

stop() {
	printf 'Stopping sshd: '

	if start-stop-daemon -p /run/sshd.pid -x /usr/sbin/sshd -o -q -K; then
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
