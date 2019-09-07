#!/bin/sh

DAEMON="knockd"
PIDFILE="/var/run/$DAEMON.pid"

KNOCKD_ARGS=""

case "$1" in
  start)
	printf "Iniciando %s: " "$DAEMON"
	start-stop-daemon -q -p "$PIDFILE" -x "/usr/sbin/$DAEMON" -S -- -p "$PIDFILE" -d $KNOCKD_ARGS
	[ $? = 0 ] && echo "OK" || echo "ERROR"
	;;
  stop)
	printf "Deteniendo %s: " "$DAEMON"
	start-stop-daemon -q -p "$PIDFILE" -K -x "/usr/sbin/$DAEMON"
	[ $? = 0 ] && echo "OK" || echo "FAIL"
	;;
  restart|reload)
	"$0" stop
	"$0" start
	;;
  *)
	echo "Usage: $0 {start|stop|restart|reload}"
	exit 1
esac

exit $?
