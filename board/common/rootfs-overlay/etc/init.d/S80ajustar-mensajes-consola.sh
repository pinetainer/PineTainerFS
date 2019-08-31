#!/bin/sh

# Solo se mostrarán por consola los mensajes con un nivel
# de prioridad inferior al especificado en la siguiente variable
# (es decir, más importantes).
readonly NIVEL_REGISTRO_CONSOLA=2

printf 'Estableciendo nivel de registro en consola a %s... ' $NIVEL_REGISTRO_CONSOLA
configPrintk=$(cat /proc/sys/kernel/printk 2>/dev/null | cut -f2,3,4 2>/dev/null) || error=1
printf '%s       %s' $NIVEL_REGISTRO_CONSOLA "$configPrintk" > /proc/sys/kernel/printk 2>/dev/null || error=1

if [ -z "$error" ]; then
	printf 'OK\n'
else
	printf 'ERROR\n'
fi
