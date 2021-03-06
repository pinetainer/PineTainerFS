#!/bin/sh

# Tweak network, dnsmasq, udev, haveged and urandom seed storage start order
mv "${1:?}/etc/init.d/S40network" "${1:?}/etc/init.d/S03network.sh" 2>/dev/null || true
mv "${1:?}/etc/init.d/S20urandom" "${1:?}/etc/init.d/S01urandom.sh" 2>/dev/null || true
mv "${1:?}/etc/init.d/S80dnsmasq" "${1:?}/etc/init.d/S10dnsmasq.sh" 2>/dev/null || true
mv "${1:?}/etc/init.d/S10udev" "${1:?}/etc/init.d/S90udev.sh" 2>/dev/null || true
mv "${1:?}/etc/init.d/S21haveged" "${1:?}/etc/init.d/S01haveged.sh" 2>/dev/null || true

# Useless desktop integration (currently created by htop, qemu and latencytop)
rm -rf "${1:?}/usr/share/applications" 2>/dev/null || true
rm -rf "${1:?}/usr/share/pixmaps" 2>/dev/null || true
rm -rf "${1:?}/usr/share/icons" 2>/dev/null || true
rm -rf "${1:?}/usr/share/qemu/qemu-nsis.bmp" 2>/dev/null || true
rm -rf "${1:?}/usr/share/latencytop" 2>/dev/null || true

# Remove nginx default pages
rm -rf "${1:?}/usr/share/html" 2>/dev/null || true
rm -rf "${1:?}/usr/html" 2>/dev/null || true

# qemu cruft
rm -rf "${1:?}/usr/share/qemu/firmware" 2>/dev/null || true
rm "${1:?}"/usr/share/qemu/openbios-* 2>/dev/null || true
rm "${1:?}"/usr/share/qemu/opensbi-* 2>/dev/null || true
rm "${1:?}"/usr/share/qemu/efi-* 2>/dev/null || true
rm "${1:?}"/usr/share/qemu/pxe* 2>/dev/null || true
rm "${1:?}"/usr/share/qemu/s390* 2>/dev/null || true
rm "${1:?}"/usr/share/qemu/*.fd 2>/dev/null || true

# iputils cruft
rm "${1:?}/etc/init.d/ninfod.sh" 2>/dev/null || true

# Scripts in interpreted languages we can't run
rm "${1:?}/usr/bin/stunnel3" 2>/dev/null || true
rm "${1:?}/etc/ssl/misc/tsget.pl" 2>/dev/null || true

# Empty directories created by gnuplot
rmdir "${1:?}/usr/libexec/gnuplot/5.4" 2>/dev/null || true
rmdir "${1:?}/usr/libexec/gnuplot" 2>/dev/null || true

# Configuration files irrelevant to nginx due
# to its compile options
rm "${1:?}"/etc/nginx/fastcgi* 2>/dev/null || true
rm "${1:?}"/etc/nginx/scgi* 2>/dev/null || true
rm "${1:?}"/etc/nginx/uwsgi* 2>/dev/null || true
rm "${1:?}"/etc/nginx/koi* 2>/dev/null || true
rm "${1:?}"/etc/nginx/win-* 2>/dev/null || true

# Useless ifupdown script
rm "${1:?}/etc/network/nfs_check" 2>/dev/null || true

# PCI ID list pulled in by mdev that won't be used
rm "${1:?}/usr/share/pci.ids.gz" 2>/dev/null || true

# Remove default sshd init.d script, as we want to tweak it
rm "${1:?}/etc/init.d/S50sshd" 2>/dev/null || true

# Append private SSH banner part to the public one, and
# remove the now merged private part
{
	cat "${1:?}/etc/ssh/banner" "${1:?}/etc/ssh/banner_private" >"${1:?}/etc/ssh/banner_new" && \
	mv "${1:?}/etc/ssh/banner_new" "${1:?}/etc/ssh/banner" && \
	rm "${1:?}/etc/ssh/banner_private"
} 2>/dev/null || true

# OpenSSH cruft (we use the internal SFTP implementation)
rm "${1:?}/usr/libexec/sftp-server" 2>/dev/null || true

# Remove not needed nftables files
rm -rf "${1:?}/etc/nftables" 2>/dev/null || true

# Remove default inadyn init.d script, as we want to tweak it
rm "${1:?}/etc/init.d/S70inadyn" 2>/dev/null || true
