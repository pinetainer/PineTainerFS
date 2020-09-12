#!/bin/sh

# Remove chrony service file, as we use our own
rm "${1:?}/etc/init.d/S49chrony" 2>/dev/null || true

# Remove useless operating system distribution information
rm "${1:?}/etc/os-release" 2>/dev/null
rm "${1:?}/usr/lib/os-release" 2>/dev/null || true
rm "${1:?}/usr/lib64/os-release" 2>/dev/null || true

# Remove rmt, which is a executable used by tar only for
# legacy devices
rm "${1:?}/libexec/rmt" 2>/dev/null || true
rmdir "${1:?}/libexec" 2>/dev/null || true

# Remove LVM configuration files which take 100 KiB of space
rm "${1:?}/etc/lvm/lvm.conf" 2>/dev/null || true
rm "${1:?}/etc/lvm/lvmlocal.conf" 2>/dev/null || true

# Remove useless configuration file
rm "${1:?}/etc/wgetrc" 2>/dev/null || true

# Scripts in interpreted languages we can't run
rm "${1:?}/usr/lib/libstdc++.so.6.0.28-gdb.py" 2>/dev/null || true

# Shell scripts with bashisms
rm "${1:?}/usr/bin/xzegrep" 2>/dev/null || true
rm "${1:?}/usr/bin/xzfgrep" 2>/dev/null || true
rm "${1:?}/usr/bin/xzcmp" 2>/dev/null || true
rm "${1:?}/usr/bin/xzdiff" 2>/dev/null || true
rm "${1:?}/usr/bin/xzgrep" 2>/dev/null || true
rm "${1:?}/usr/bin/xzless" 2>/dev/null || true
rm "${1:?}/usr/bin/xzmore" 2>/dev/null || true

# Files in directories on which a RAM filesystem will be mounted
rm -rf "${1:?}"/dev/* 2>/dev/null || true
rm -rf "${1:?}"/run/* 2>/dev/null || true
rm -rf "${1:?}"/tmp/* 2>/dev/null || true
