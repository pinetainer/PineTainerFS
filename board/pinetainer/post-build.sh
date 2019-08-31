#!/bin/sh

# Eliminar fichero sudoers.dist innecesario
rm -f "$1/etc/sudoers.dist" || true

# El inicio del servicio de watchdog es prioritario
mv "$1/etc/init.d/S15watchdog" "$1/etc/init.d/S00watchdog.sh" || true

# Sustituir llamada a /bin/mount por ejecución de un script
sed -i '/^mnt::sysinit:/cmnt::sysinit:/etc/init.d/mountfs' "$1/etc/inittab"
