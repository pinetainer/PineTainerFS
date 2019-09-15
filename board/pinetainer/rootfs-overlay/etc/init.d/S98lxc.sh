#!/bin/sh

case "$1" in
  start)
	printf "Iniciando contenedores de LXC: "
	lxc-autostart
	{
		[ $? = 0 ] && echo "OK"
	} || echo "ERROR"
	;;
  stop)
	printf "Deteniendo contenedores de LXC: "
	lxc-autostart -saA -t5
	{
		[ $? = 0 ] && echo "OK"
	} || echo "ERROR"
	;;
  restart|reload)
	"$0" stop
	"$0" start
	;;
  *)
	echo "Sintaxis: $0 {start|stop|restart|reload}"
	exit 1
esac

exit $?
