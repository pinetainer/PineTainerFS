#!/bin/sh

moverProcesoACgroup() {
	for controlador in /sys/fs/cgroup/*; do
                if [ -d "$controlador/$2" ]; then
                        echo $1 >> "$controlador/$2/tasks"
                fi
        done
}

case "$1" in
  start)
	printf "Iniciando contenedores de LXC: "
	# Los contenedores heredarán el cgroup del proceso init
	moverProcesoACgroup 1 'lxc'
	/usr/libexec/lxc/lxc-containers $1
	{
		[ $? = 0 ] && echo "OK"
	} || echo "ERROR"
	moverProcesoACgroup 1 'system'
	;;
  stop)
	printf "Deteniendo contenedores de LXC: "
	/usr/libexec/lxc/lxc-containers $1
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
