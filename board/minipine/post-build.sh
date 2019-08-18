#!/bin/sh
# Información de versión más apropiada que la predeterminada
printf "NAME=\"Linux\"\nVERSION=\"5.3-rc4\"\nID=linux\nID_LIKE=\"buildroot\"\nHOME_URL=\"https://github.com/pinetainer\"\nVARIANT=\"minipine\"\nVARIANT_ID=\"minipine\"" > "$1/usr/lib/os-release"

# Eliminar servicio no útil, ignorando errores si ya fue borrado
rm "$1/etc/init.d/S20urandom" || true

# Eliminar archivos de firmware innecesarios
find "$1/firmware/rtlwifi" -type f -name '*.bin' \! -name 'rtl8723bs_nic.bin' -exec rm {} \;
