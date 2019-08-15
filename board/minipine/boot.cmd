setenv bootargs root=/dev/mmcblk0p2 rootwait

fatload mmc 0 $kernel_addr_r Image
fatload mmc 0 $fdt_addr_r sun50i-h6-pine-h64.dtb

booti $kernel_addr_r - $fdt_addr_r
