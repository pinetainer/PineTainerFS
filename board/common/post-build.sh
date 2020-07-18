#!/bin/sh

# Tweak urandom service start order
mv "${1:?}/etc/init.d/S20urandom" "${1:?}/etc/init.d/S01urandom" 2>/dev/null || true

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

# Useless Dropbear executables and init scripts
rm "${1:?}/usr/bin/dropbearkey" 2>/dev/null || true
rm "${1:?}/usr/bin/dropbearconvert" 2>/dev/null || true
rm "${1:?}/etc/init.d/S50dropbear" 2>/dev/null || true

# Save ~200 MiB in useless files
for dri_lib in \
armada-drm_dri.so hx8357d_dri.so ili9341_dri.so ingenic-drm_dri.so meson_dri.so \
mxsfb-drm_dri.so pl111_dri.so rockchip_dri.so st7735r_dri.so exynos_dri.so \
ili9225_dri.so imx-drm_dri.so mcde_dri.so mi0283qt_dri.so repaper_dri.so \
st7586_dri.so stm_dri.so
do
    rm "${1:?}/usr/lib/dri/$dri_lib" || true
done
