#!/bin/sh

# Eliminar fichero sudoers.dist innecesario
rm -f "$1/etc/sudoers.dist" || true

# El inicio del servicio de watchdog es prioritario
mv "$1/etc/init.d/S15watchdog" "$1/etc/init.d/S00watchdog.sh" || true
