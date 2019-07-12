#!/bin/sh
# Información de versión más apropiada que la predeterminada
printf "NAME=\"Linux\"\nVERSION=\"5.1.6\"\nID=linux\nID_LIKE=\"buildroot\"\nHOME_URL=\"https://github.com/pinetainer\"\nVARIANT=\"minipine\"\nVARIANT_ID=\"minipine\"" > "$1/usr/lib/os-release"

# Eliminar servicio no útil, ignorando errores si ya fue borrado
rm "$1/etc/init.d/S20urandom" || true
