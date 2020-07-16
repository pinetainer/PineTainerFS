# PineTainerFS
Buildroot scripts and configuration files used for compiling the Linux kernel and generating the root filesystem for PineTainer.

## Quick start
After cloning this repository for the first time, you'll probably be interested in getting your own PineUp copy. PineUp is a tiny OS that can be copied to a SD card whose purpose is to allow installing a proper PineTainer image, and performing hardware and/or software tests.

To do that, you should run the following commands, in the order that they are shown. It is assumed that their working directory is the root of this repository. A basic literacy on how to use Buildroot is also assumed. A brief explanation of what they do follows.

```console
$ scripts/update-and-patch-buildroot.sh -yu
$ ./make.sh pineup_defconfig
$ ./make.sh nconfig (temporarily remove "-flto" from Toolchain -> Target Optimizations and save)
$ ./make.sh uboot
$ ./make.sh nconfig (readd "-flto" to Toolchain -> Target Optimizations and save)
$ scripts/fix-toolchain-lto.sh
$ cd scripts
$ sudo ./install-firmware-blobs.sh
$ cd ..
$ ./make.sh
```

The first command (`scripts/update-and-patch-buildroot.sh -yu`) checks out the appropriate commit of the Buildroot upstream submodule and applies the patches in `buildroot-patches` to it. Next, the `make.sh` wrapper calls the Buildroot Makefile with the `pineup_defconfig` parameter, among others that set the execution environment so that the Buildroot artifacts are nicely contained in the `build` subdirectory.

The next three commands work around compile errors which occur when link time optimization (LTO) is used to compile U-Boot, by disabling LTO temporarily, compiling the U-Boot and its (mostly host-side) dependencies, and then reenabling LTO.

The following command replaces some executables in Buildroot's copy of the `aarch64-pinechain-linux-musl_sdk-buildroot` toolchain by wrappers that load the necessary linker plugins for LTO to work. The external toolchain should be placed in the root directory of the repository, and must be downloaded separatedly or generated with `./make.sh pinechain_defconfig && ./make.sh`.

Once the toolchain is fixed, we install propietary Realtek 8723BS firmware blobs to the system, so they can be included in the resulting kernel image and Wi-Fi and Bluetooth can work. If you don't want closed source blobs in your kernel, skip this step and change the `CONFIG_EXTRA_FIRMWARE` Linux kernel configuration so that it doesn't try to include these in the image.

Finally, the rest of the root filesystem is built normally with `./make.sh`. Go out there and have some fun while it does its thing.
