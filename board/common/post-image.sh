#!/bin/sh

# Script based on Buildroot's support/scripts/genimage.sh

# Generates a boot.cfg genimage configuration file on the fly,
# so that it defines a boot.vfat image with the desired boot
# files in the appropriate places, and then runs the specified
# specific genimage configuration

# Directory for genimage temporary files.
readonly GENIMAGE_TMP="$BUILD_DIR/tmp_genimage"
# Filename of the generated kernel image.
readonly KERNEL_IMAGE='Image'
# The filename of the automatically generated boot image configuration.
readonly BOOT_CFG="$BINARIES_DIR/boot.cfg"

# Prints a usage message to stdout and exits
# with error status.
printUsage() {
	printf 'Usage: %s -c CONFIG_FILE\n' "$0"
	exit 1
}

# Adds an entry to a boot image configuration file, representing a file
# in the boot image.
# $1: the name of the file in the image.
# $2: the image name in the input directory.
addFileEntry() {
	printf '\t\tfile %s {\n\t\t\timage = "%s"\n\t\t}\n' "$1" "$2" >> "$BOOT_CFG"
}

# Creates a link to a file in a directory. If the directory
# doesn't exist, it's created automatically. If any errors
# occur during the operation, the script aborts.
# $1: the file to create a link to.
# $2: the directory to create a link in.
linkInDir() {
	linkBasename=$(basename "$1")

	printf 'Creating link to %s in %s...\n' "$1" "$2/$linkBasename"

	if [ ! -d "$2" ]; then
		mkdir -p "$2" || exit $?
	fi

	if [ ! -L "$2/$linkBasename" ]; then
		ln -s "$1" "$2/$linkBasename" || exit $?
	fi
}

# Discard first argument. It confuses getopts
shift

# Parse command line options
while getopts 'c:' opt; do
	case "$opt" in
		c) GENIMAGE_CONFIG="$OPTARG";;
		*) break;;
	esac
done

# We need GENIMAGE_CONFIG set to a filename
[ -r "${GENIMAGE_CONFIG}" ] || printUsage

# Create a symbolic link to extlinux.conf in the images directory
linkInDir "$BR2_EXTERNAL_PINETAINER_PATH/board/common/extlinux.conf" "$BINARIES_DIR"

# Get the generated DTB files
for dtb in "$BINARIES_DIR"/*.dtb; do
	if [ -f "$dtb" ]; then
		if [ -z "$DTBS" ]; then
			DTBS="$dtb"
		else
			DTBS=$(printf '%s\n%s' "$DTBS" "$dtb")
		fi
	fi
done

# Calculate the total size of the files that will be inside the boot partition.
# Also generate boot.vfat image script from the corresponding boot files
printf 'image boot.vfat {\n\tvfat {\n' > "$BOOT_CFG"
BOOT_FILES_SIZE=0
IFS='
'
for file in $(printf '%s\n%s\n%s' "$BINARIES_DIR/extlinux.conf" "$BINARIES_DIR/$KERNEL_IMAGE" "$DTBS"); do
	currentFileSize=$(wc -c "$file" 2>/dev/null)
	currentFileSize=${currentFileSize% *}

	# Check that the file size is a number (might not be if file does not exist)
	if [ "$currentFileSize" -eq "$currentFileSize" ] 2>/dev/null; then
		printf 'Adding %s to boot.vfat: %d bytes\n' "$file" "$currentFileSize"
		fileBasename=$(basename "$file")

		if [ "$fileBasename" = "extlinux.conf" ]; then
			# extlinux.conf goes in extlinux subfolder
			addFileEntry "extlinux/$fileBasename" "$fileBasename"
		elif [ -z "${fileBasename%%*.dtb}" ]; then
			# DTBs go in dtb/allwinner subfolder
			addFileEntry "dtb/allwinner/$fileBasename" "$fileBasename"
		else
			# No special handling for other files
			addFileEntry "$fileBasename" "$fileBasename"
		fi

		BOOT_FILES_SIZE=$((BOOT_FILES_SIZE + currentFileSize))
	fi
done
unset IFS

# Add 2 MiB to the size for filesystem and/or administrator use, and finish off the BOOT_CFG file
BOOT_FILES_SIZE=$((BOOT_FILES_SIZE + 2097152))
printf 'Total boot.vfat size: %d bytes (%d MiB)\n\n' $BOOT_FILES_SIZE $((BOOT_FILES_SIZE / 1048576))
printf '\t}\n\tsize = %s\n}' "$BOOT_FILES_SIZE" >> "$BOOT_CFG"

# Finally, generate the sdcard.img image
currentPwd="$PWD"
# Temporarily change directory to binaries dir, so the generated configuration can be included
cd "$BINARIES_DIR" || exit $?
genimage \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CONFIG}"
cd "$currentPwd" || exit $?

# Delete leftovers
rm -rf "$GENIMAGE_TMP"
rm "$BINARIES_DIR/boot.vfat"
rm "$BOOT_CFG"
