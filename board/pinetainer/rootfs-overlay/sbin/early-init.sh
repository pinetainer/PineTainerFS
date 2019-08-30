#!/bin/sh

# Este script lleva a cabo tareas que corresponde realizar antes de que init
# tome el control del estado de ejecución del sistema:
# - Iniciar la vigilancia del perro guardián (watchdog)
# - Montar el sistema de ficheros raíz (ro) como un overlay (rw)
# - Configurar los parámetros de iluminación de los LED indicadores de actividad
# - Montar sistemas de ficheros esenciales (proc, sys, run)
# En cierto modo, sustituye a un disco en RAM inicial típico de otras distribuciones
# de Linux, que es innecesariamente complicado para nuestros requisitos.

# El LED que parpadeará para indicar un error en la ejecución de este script,
# si se pudo montar /sys.
readonly LED_ERROR=/sys/class/leds/pine-h64:green:heartbeat
# El dispositivo donde se encuentra el sistema de ficheros superior del
# overlay.
readonly DISPOSITIVO_UPPER='/dev/mmcblk2p3'
# Las opciones de montaje del sistema de ficheros que se encontrará en la capa
# superior del overlay.
readonly OPCIONES_MONTAJE_UPPER='lazytime'
# El directorio en el sistema de ficheros de la capa inferior que contendrá
# los subdirectorios upper, lower y overlay donde se depositarán los sistemas
# de ficheros superior, inferior y el punto de montaje temporal del overlay,
# respectivamente.
readonly DIR_OVERLAY='/media/rootfs-overlay'

# PATH donde se encuentran los ejecutables a usar por este script.
readonly PATH='/bin:/sbin'

# Muestra que ha ocurrido un error grave por la salida estándar.
# Además de eso, señaliza la ocurrencia de un error mediante los LED
# de la Pine.
# $1: una descripción textual de lo que se estaba intentando hacer.
# $2: un código de error numérico.
mostrarErrorGrave() {
	printf '\n! Ha ocurrido un error grave durante la siguiente operación: %s. Código de error: %s.\n' "$1" "$2"

	# Hacer el mejor intento posible para desmontar todos los sistemas de ficheros
	# (quizás hayamos montado el sistema de ficheros de la capa superior del overlay,
	# que es de escritura)
	umount -a

	# Si el directorio que representa un LED de la Pine no está disponible,
	# quizás sea porque no se montó /sys. Intentar montar /sys
	# (dentro de un if porque el comando anterior pudo fallar y no haber
	# desmontado nada)
	if [ ! -d "$LED_ERROR" ]; then
		mount -t sysfs sysfs /sys
	fi

	# Solo gestionar el LED si tenemos acceso a su objeto en /sys
	if [ -d "$LED_ERROR" ]; then
		# Realizar un latido lento y descompensado, para avisar visualmente al
		# operador de que posiblemente necesitemos sus poderes de desfibrilación
		printf 'pattern' > "$LED_ERROR/trigger"
		printf '1 2000 0 200 1 200 0 200 1 200 0 5000' > "$LED_ERROR/pattern"
	fi

	# No hacer nada, para siempre, sin salir de este proceso.
	# Así evitamos que el kernel entre en pánico porque init
	# finalice
	while true; do
		sleep 2212
	done
}

# /dev siempre está disponible, pues compilamos el kernel con
# soporte para devtmpfs. Decirle entonces a nuestro fiel perro
# guardián que nos reinicie si el espacio de usuario no le informa
# de que todo está bien (porque ocurrió un error durante la ejecución
# de este script, por ejemplo) en un plazo de 16 segundos
: > /dev/watchdog

# Montar el sistema de ficheros superior (rw)
if [ -n "$OPCIONES_MONTAJE_UPPER" ]; then
	mount -o "$OPCIONES_MONTAJE_UPPER,rw" $DISPOSITIVO_UPPER "$DIR_OVERLAY/upper" > /dev/null
else
	mount $DISPOSITIVO_UPPER "$DIR_OVERLAY/upper" > /dev/null
fi || mostrarErrorGrave "montaje de $DISPOSITIVO_UPPER" $?

# Crear los directorios necesarios en el sistema de ficheros superior
# si es necesario
mkdir -p "$DIR_OVERLAY/upper/rootfs-overlay-files" || mostrarErrorGrave "creación del punto de montaje para el sistema de ficheros superior" $?
mkdir -p "$DIR_OVERLAY/upper/work" || mostrarErrorGrave "creación del directorio de trabajo del overlay" $?

# Montar el overlay
mount -t overlay -o lowerdir=/,upperdir=$DIR_OVERLAY/upper/rootfs-overlay-files,workdir=$DIR_OVERLAY/upper/work overlay $DIR_OVERLAY/overlay || mostrarErrorGrave "montaje del overlay" $?

# Hacer nuestro devtmpfs accesible desde el overlay
# (naturalmente, el overlay solo combina directorios y ficheros, no sistemas de ficheros montados)
mount --bind /dev "$DIR_OVERLAY/overlay/dev" || mostrarErrorGrave "montaje de alias para devtmpfs en overlay" $?
# Desmontar /dev no parece demasiado correcto que digamos, pero funciona
# (¿no se supone que el terminal tiene abierto el fichero del terminal de la salida estándar?).
# Es útil intentar desmontarlo de todos modos para evitar tener montado dos veces devtmpfs, y ahorrar
# memoria. Pero tampoco es merecedor de un error grave que no lo hayamos podido desmontar
umount /dev || echo '! No se pudo desmontar el devtmpfs del sistema de ficheros raíz original. Continuando de todos modos.'

# Cambiar el directorio raíz al overlay. Antes establecemos el directorio
# de trabajo a la nueva raíz para hacer más sencillo dejar de utilizar ficheros
# en el anterior sistema de ficheros raíz, independientemente de cómo se haya
# podido implementar pivot_root
cd "$DIR_OVERLAY/overlay" || mostrarErrorGrave "cambio de directorio al directorio del overlay montado" $?
pivot_root . "${DIR_OVERLAY#/}/lower" || mostrarErrorGrave "cambio de sistema de ficheros raíz con pivot_root" $?

# Montar algunos sistemas de ficheros esenciales
bin/mount -t proc proc proc || mostrarErrorGrave "montaje de /proc" $?
bin/mount -t sysfs sysfs sys || mostrarErrorGrave "montaje de /sys" $?
bin/mount -t tmpfs -o mode=0755,nosuid,nodev tmpfs run || mostrarErrorGrave "montaje de /run" $?

# Si hay directorios temporales de montaje de overlay en la vista del overlay,
# borrarlos para que quede más bonito
if [ -d "${DIR_OVERLAY#/}/overlay" ]; then
	bin/rmdir "${DIR_OVERLAY#/}/overlay"
fi
if [ -d "${DIR_OVERLAY#/}/upper" ]; then
	bin/rmdir "${DIR_OVERLAY#/}/upper"
fi

# Configurar disparadores de LEDs para indicar actividad de manera visual
# al operador. Ignoramos errores que pudieran ocurrir, pues esto no es
# vital para el funcionamiento del sistema
printf 'heartbeat' > sys/class/leds/pine-h64:green:heartbeat/trigger 2>dev/null
if [ -n "${DISPOSITIVO_UPPER%/dev/mmcblk*}" ]; then
	dispositivoYPartMMC=${DISPOSITIVO_UPPER#/dev/mmcblk}
	printf 'mmc%d' "${dispositivoYPartMMC%p*}" > sys/class/leds/pine-h64:blue:status/trigger 2>/dev/null
fi

# Finalmente, delegar el control al proceso init auténtico
exec usr/sbin/chroot . /sbin/init $@ <dev/console >dev/console 2>&1 || mostrarErrorGrave "delegación del control a /sbin/init" $?
