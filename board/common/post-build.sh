#!/bin/sh
# Información de versión más apropiada que la predeterminada
printf "NAME=\"Linux\"\nVERSION=\"5.3-rc6\"\nID=linux\nID_LIKE=\"buildroot\"\nHOME_URL=\"https://github.com/pinetainer\"\nVARIANT=\"minipine\"\nVARIANT_ID=\"minipine\"" > "$1/usr/lib/os-release"

# Borrar ficheros inútiles solo usados por bash
rm -rf "$1/etc/bash_completion.d" || true

# Hacer que urandom sea de los primeros servicios en ser iniciado,
# para tener acceso a mayor aleatoriedad antes
mv "$1/etc/init.d/S20urandom" "$1/etc/init.d/S01urandom.sh" || true

# Borrar ficheros que cuelgan de directorios temporales
rm -rf "$1/tmp/*" || true
rm -rf "$1/run/*" || true
find "$1/dev" -mindepth 1 -delete || true

# Borrar rmt y el directorio que lo contiene, si queda vacío
rm -f "$1/libexec/rmt" || true
rmdir "$1/libexec" 2>/dev/null || true
