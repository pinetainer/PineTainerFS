#!/bin/sh

# Useless Dropbear executables and init scripts
rm "${1:?}/usr/bin/dropbearkey" 2>/dev/null || true
rm "${1:?}/usr/bin/dropbearconvert" 2>/dev/null || true
rm "${1:?}/etc/init.d/S50dropbear" 2>/dev/null || true

# Useless desktop integration (currently created by htop and qemu-xen)
rm -rf "${1:?}/usr/share/applications" 2>/dev/null || true
rm -rf "${1:?}/usr/share/pixmaps" 2>/dev/null || true
rm -rf "${1:?}/usr/share/qemu-xen/applications" 2>/dev/null || true
rm -rf "${1:?}/usr/share/qemu-xen/icons" 2>/dev/null || true
rm -rf "${1:?}/usr/share/qemu-xen/qemu-nsis.bmp" 2>/dev/null || true

# Remove nginx default pages
rm -rf "${1:?}/usr/share/html" 2>/dev/null || true

# qemu-xen cruft for other architectures
rm "${1:?}/usr/share/qemu-xen/qemu/firmware/50-edk2-x86_64-secure.json" 2>/dev/null || true
rm "${1:?}/usr/share/qemu-xen/qemu/firmware/50-edk2-x86_64-secure.json" 2>/dev/null || true
rm "${1:?}/usr/share/qemu-xen/qemu/firmware/60-edk2-x86_64.json" 2>/dev/null || true
rm "${1:?}/usr/share/qemu-xen/qemu/openbios-sparc32" 2>/dev/null || true
rm "${1:?}/usr/share/qemu-xen/qemu/openbios-sparc64" 2>/dev/null || true
rm "${1:?}/usr/share/qemu-xen/qemu/opensbi-*" 2>/dev/null || true
rm "${1:?}/usr/share/qemu-xen/qemu/efi-*" 2>/dev/null || true
rm "${1:?}/usr/share/qemu-xen/qemu/ppc_rom.bin" 2>/dev/null || true
rm "${1:?}/usr/share/qemu-xen/qemu/pxe*" 2>/dev/null || true

# Scripts in interpreted languages we can't run
rm "${1:?}/usr/bin/stunnel3" 2>/dev/null || true
rm "${1:?}/usr/bin/smime_keys" 2>/dev/null || true
rm "${1:?}/usr/bin/xencov_split" 2>/dev/null || true
rm "${1:?}/usr/sbin/xencons" 2>/dev/null || true
rm "${1:?}/usr/sbin/xentrace_format" 2>/dev/null || true
rm "${1:?}/usr/sbin/exigrep" 2>/dev/null || true
rm "${1:?}/usr/sbin/eximstats" 2>/dev/null || true
rm "${1:?}/usr/sbin/exipick" 2>/dev/null || true
rm "${1:?}/usr/sbin/exiqgrep" 2>/dev/null || true
rm "${1:?}/usr/sbin/exiqsumm" 2>/dev/null || true
rm "${1:?}/usr/sbin/xenmon" 2>/dev/null || true
rm "${1:?}/usr/lib/xen/bin/xenpvnetboot" 2>/dev/null || true
rm "${1:?}/etc/ssl/misc/tsget.pl" 2>/dev/null || true

# Shell scripts with bashisms
rm "${1:?}/usr/lib/xen/bin/xendomains" 2>/dev/null || true

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

# Useless Xen configuration files
rm "${1:?}/etc/sysconfig/xendomains" 2>/dev/null || true
