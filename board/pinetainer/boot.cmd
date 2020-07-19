echo "Loading Pine H64 model B device tree..."
if load mmc ${mmc_bootdev} ${fdt_addr_r} sun50i-h6-pine-h64-model-b.dtb; then
	echo "Loading Xen hypervisor..."

	if load mmc ${mmc_bootdev} ${ramdisk_addr_r} xen; then
		echo "Loading dom0 kernel image file..."

		if load mmc ${mmc_bootdev} ${kernel_addr_r} Image; then
			echo "Tweaking device tree for Xen..."

			fdt addr ${fdt_addr_r}
			fdt resize
			fdt chosen

			fdt set /chosen \#address-cells <1>
			fdt set /chosen \#size-cells <1>
			fdt mknod /chosen module@0
			fdt set /chosen/module@0 compatible "xen,linux-zimage" "xen,multiboot-module"
			fdt set /chosen/module@0 reg <${kernel_addr_r} 0x${filesize}>

			fdt set /chosen xen,xen-bootargs "console=dtuart dtuart=/soc/serial@5000000 console_timestamps=boot cpufreq=dom0-kernel dom0_mem=512M loglvl=info vwfi=native"
			setenv bootargs console=hvc0 earlycon=xenboot root=/dev/mmcblk2p2 rootwait clk_ignore_unused

			booti ${ramdisk_addr_r} - ${fdt_addr_r}
		else
			echo "! An error occurred while loading the kernel image."

			led pine-h64:blue:status on
			sleep 5
			led pine-h64:blue:status off
		fi
	else
		echo "! An error occurred while loading the Xen hypervisor."

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
