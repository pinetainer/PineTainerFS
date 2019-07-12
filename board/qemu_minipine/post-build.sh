#!/bin/sh
# Información de versión más apropiada que la predeterminada
printf "NAME=\"Linux\"\nVERSION=\"5.1.6\"\nID=linux\nID_LIKE=\"buildroot\"\nHOME_URL=\"https://github.com/pinetainer\"\nVARIANT=\"$2\"\nVARIANT_ID=\"$2\"" > "$1/usr/lib/os-release"

# Eliminar servicio no útil
rm "$1/etc/init.d/S20urandom"
