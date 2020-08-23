#!/bin/sh

case "$1" in
	start)			printf 'Starting chrony: '
					chronyd && echo 'OK' || echo 'ERROR';;
	stop)			printf 'Stopping chrony: '
					killall chronyd && echo 'OK' || echo 'ERROR';;
	restart|reload)	"$0" stop
					"$0" start;;
	*)				echo "Usage: $0 {start|stop|restart}"
  					exit 1
esac
