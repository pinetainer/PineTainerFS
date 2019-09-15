#!/bin/sh

# Eliminar fichero sudoers.dist innecesario
rm -f "$1/etc/sudoers.dist" || true

# El inicio del servicio de watchdog es prioritario
mv "$1/etc/init.d/S15watchdog" "$1/etc/init.d/S00watchdog.sh" || true

# Sustituir llamada a /bin/mount por ejecución de un script
sed -i '/^mnt::sysinit:/cmnt::sysinit:/etc/init.d/mountfs' "$1/etc/inittab"

# Desactivar inicio automático de Dropbear, y crear directorio
# para guardado de claves, pues el sistema de ficheros final será
# RW
rm -f "$1/etc/init.d/S50dropbear"
rm -f "$1/etc/dropbear"
mkdir -p "$1/etc/dropbear"

# Dar permisos restrictivos al fichero wpa_supplicant.conf, si existe
if [ -f "$1/etc/wpa_supplicant.conf" ]; then
	chmod 660 "$1/etc/wpa_supplicant.conf"
fi

# Eliminar ficheros innecesarios generados por LXC
rm -rf "$1/usr/share/lxc/selinux" || true
