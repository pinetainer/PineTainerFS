#!/bin/sh

DAEMON="xinetd"
PIDFILE="/var/run/$DAEMON.pid"

XINETD_ARGS=""

case "$1" in
  start)
	printf "Iniciando superservidor %s: " "$DAEMON"
	start-stop-daemon -q -p "$PIDFILE" -b -x "/usr/sbin/$DAEMON" -S -- -dontfork -pidfile "$PIDFILE" $XINETD_ARGS
	[ $? = 0 ] && echo "OK" || echo "ERROR"
	;;
  stop)
	printf "Deteniendo superservidor %s: " "$DAEMON"
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
