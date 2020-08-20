#!/bin/sh

# Tweak network, dnsmasq and udev start order
mv "${1:?}/etc/init.d/S40network" "${1:?}/etc/init.d/S03network.sh" 2>/dev/null || true
mv "${1:?}/etc/init.d/S80dnsmasq" "${1:?}/etc/init.d/S04dnsmasq.sh" 2>/dev/null || true
mv "${1:?}/etc/init.d/S10udev" "${1:?}/etc/init.d/S90udev.sh" 2>/dev/null || true

# Useless Dropbear executables and init scripts
rm "${1:?}/usr/bin/dropbearkey" 2>/dev/null || true
rm "${1:?}/usr/bin/dropbearconvert" 2>/dev/null || true
rm "${1:?}/etc/init.d/S50dropbear" 2>/dev/null || true

# Useless desktop integration (currently created by htop and qemu)
rm -rf "${1:?}/usr/share/applications" 2>/dev/null || true
rm -rf "${1:?}/usr/share/pixmaps" 2>/dev/null || true
rm -rf "${1:?}/usr/share/icons" 2>/dev/null || true
rm -rf "${1:?}/usr/share/qemu/qemu-nsis.bmp" 2>/dev/null || true

# Remove nginx default pages
rm -rf "${1:?}/usr/share/html" 2>/dev/null || true
rm -rf "${1:?}/usr/html" 2>/dev/null || true

# qemu cruft
rm -rf "${1:?}/usr/share/qemu/firmware" 2>/dev/null || true
rm "${1:?}/usr/share/qemu/openbios-*" 2>/dev/null || true
rm "${1:?}/usr/share/qemu/opensbi-*" 2>/dev/null || true
rm "${1:?}/usr/share/qemu/efi-*" 2>/dev/null || true
rm "${1:?}/usr/share/qemu/pxe*" 2>/dev/null || true
rm "${1:?}/usr/share/qemu/s390*" 2>/dev/null || true
rm "${1:?}/usr/share/qemu/*.fd" 2>/dev/null || true

# iputils cruft
rm "${1:?}/etc/init.d/ninfod.sh" 2>/dev/null || true

# Scripts in interpreted languages we can't run
rm "${1:?}/usr/bin/stunnel3" 2>/dev/null || true
rm "${1:?}/usr/bin/smime_keys" 2>/dev/null || true
rm "${1:?}/usr/sbin/exigrep" 2>/dev/null || true
rm "${1:?}/usr/sbin/eximstats" 2>/dev/null || true
rm "${1:?}/usr/sbin/exipick" 2>/dev/null || true
rm "${1:?}/usr/sbin/exiqgrep" 2>/dev/null || true
rm "${1:?}/usr/sbin/exiqsumm" 2>/dev/null || true
rm "${1:?}/etc/ssl/misc/tsget.pl" 2>/dev/null || true

# Build configuration for Dovecot. Contains possibly sensitive data,
# like full paths in the build host. Who in the Dovecot development
# team thought this would be a good idea, not worth of being disabled
# in a configure option? :(
rm "${1:?}/usr/lib/dovecot-config" 2>/dev/null || true

# Empty directories created by gnuplot
rmdir "${1:?}/usr/libexec/gnuplot/5.2" 2>/dev/null || true
rmdir "${1:?}/usr/libexec/gnuplot" 2>/dev/null || true

# Configuration files irrelevant to nginx due
# to its compile options
rm "${1:?}/etc/nginx/fastcgi*" 2>/dev/null || true
rm "${1:?}/etc/nginx/scgi*" 2>/dev/null || true
rm "${1:?}/etc/nginx/uwsgi*" 2>/dev/null || true
rm "${1:?}/etc/nginx/koi*" 2>/dev/null || true
rm "${1:?}/etc/nginx/win-*" 2>/dev/null || true

# Useless ifupdown script
rm "${1:?}/etc/network/nfs_check" 2>/dev/null || true
