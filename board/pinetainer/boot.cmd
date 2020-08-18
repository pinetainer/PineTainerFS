echo "Loading Pine H64 model B device tree..."
if load mmc ${mmc_bootdev} ${fdt_addr_r} sun50i-h6-pine-h64-model-b.dtb; then
	echo "Loading kernel image file..."

	if load mmc ${mmc_bootdev} ${kernel_addr_r} Image; then
		echo "Booting Linux kernel..."

		setenv bootargs console=ttyS0,115200n8 earlycon=uart,mmio32,0x05000000 root=/dev/mmcblk2p2 rootwait ifb.numifbs=1 init=/sbin/early-init.sh
		booti ${kernel_addr_r} - ${fdt_addr_r}
	else
		echo "! An error occurred while loading the kernel image."

		led pine-h64:blue:status on
		sleep 5
		led pine-h64:blue:status off
	fi
else
	echo "! An error occurred while loading the device tree."

	led pine-h64:blue:status on
	sleep 5
	led pine-h64:blue:status off
fi
