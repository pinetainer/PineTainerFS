setenv bootargs console=ttyS0,115200n8 console=tty0 root=/dev/mmcblk0p2 rootwait earlycon=uart,mmio32,0x05000000

load mmc {$mmc_bootdev}:1 40080000 Image
load mmc {$mmc_bootdev}:1 4fa00000 sun50i-h6-pine-h64.dtb

booti 40080000 - 4fa00000
