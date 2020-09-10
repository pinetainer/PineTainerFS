#!/bin/sh
exec qemu-system-aarch64 -machine virt,virtualization=on,iommu=smmuv3,gic-version=max,mem-merge=on \
-cpu max -accel kvm -smp "$VCPUS" -m "$MAIN_MEMORY_SIZE" \
-chardev "socket,id=char0,path=$CONTROL_SOCKET_DIR/ttyAMA0.sock,server,nowait" \
-serial chardev:char0 \
-drive "file=$QEMU_EFI_PFLASH_IMAGE,if=pflash,format=raw,readonly=on,aio=native,cache.direct=on" \
-drive "file=$NVRAM_BLOCK_DEVICE,if=pflash,format=raw,aio=native,cache.direct=on" \
-drive "file=$MAIN_BLOCK_DEVICE,if=virtio,format=raw,aio=native,cache.direct=on" \
-netdev "tap,id=tap0,ifname=$TAP_INTERFACE_NAME,script=$TAP_INTERFACE_UP_SCRIPT,downscript=no" \
-device "virtio-net-pci,netdev=tap0,mac=$VIRTUAL_INTERFACE_MAC" \
-device virtio-balloon-pci,deflate-on-oom=on \
-watchdog i6300esb -watchdog-action reset \
-object rng-random,id=rng0,filename=/dev/urandom \
-device virtio-rng-pci,rng=rng0 \
-object cryptodev-backend-builtin,id=cryptodev0 \
-device virtio-crypto-pci,id=crypto0,cryptodev=cryptodev0 \
-chardev "socket,id=char1,path=$CONTROL_SOCKET_DIR/monitor.sock,server,nowait" \
-mon char1 \
-display none \
-nodefaults \
"$@"
