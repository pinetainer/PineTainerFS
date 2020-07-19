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
readonly BOOT_CONFIG="$BINARIES_DIR/boot.cfg"

# Prints a usage message to stdout and exits
# with error status.
printUsage() {
	printf 'Usage: %s -c CONFIG_FILE [ -i ADDITIONAL_FILE_IN_BINARIES_DIR ... ]\n' "$0"
	exit 1
}

# Adds an entry to a boot image configuration file, representing a file
# in the boot image.
# $1: the name of the file in the image.
# $2: the image name in the input directory.
addFileEntry() {
	printf '\t\tfile %s {\n\t\t\timage = "%s"\n\t\t}\n' "$1" "$2" >> "$BOOT_CONFIG"
}

# Discard first argument. It confuses getopts
shift

# Parse command line options
while getopts 'c:i:' opt; do
	case "$opt" in
		c)	GENIMAGE_CONFIG="$OPTARG";;
		i)	ADDITIONAL_FILES="$(printf '%s\n%s' "$BINARIES_DIR/$OPTARG" "$ADDITIONAL_FILES")";;
		*)	break;;
	esac
done

# We need GENIMAGE_CONFIG set to a filename
[ -r "$GENIMAGE_CONFIG" ] || printUsage

# Get the generated DTB files
for dtb in "$BINARIES_DIR"/*.dtb; do
	if [ -f "$dtb" ]; then
		if [ -z "$DTBS" ]; then
			DTBS="$dtb"
		else
			DTBS=$(printf '%s\n%s' "$dtb" "$DTBS")
		fi
	fi
done

# Calculate the total size of the files that will be inside the boot partition.
# Also generate boot.vfat image script from the corresponding boot files
printf 'image boot.vfat {\n\tvfat {\n\t\tlabel = "BOOT_DATA"\n' > "$BOOT_CONFIG"
BOOT_FILES_SIZE=0
while read -r file; do
	currentFileSize=$(wc -c "$file" 2>/dev/null)
	currentFileSize=${currentFileSize% *}

	# Check that the file size is a number (might not be if the file does not exist)
	if [ "$currentFileSize" -eq "$currentFileSize" ] 2>/dev/null; then
		printf 'Adding %s to boot.vfat: %d bytes\n' "$file" "$currentFileSize"
		fileBasename=$(basename "$file")

		# Everything relevant goes to the root directory
		addFileEntry "$fileBasename" "$fileBasename"

		BOOT_FILES_SIZE=$((BOOT_FILES_SIZE + currentFileSize))
	fi
done <<CMD
$(printf '%s\n%s\n%s\n%s' "$BINARIES_DIR/boot.scr" "$BINARIES_DIR/$KERNEL_IMAGE" "$DTBS" "$ADDITIONAL_FILES")
CMD

# Add 1 MiB to the size for filesystem and/or administrator use, and finish off the BOOT_CONFIG file
BOOT_FILES_SIZE=$((BOOT_FILES_SIZE + 1048576))
printf 'Total boot.vfat size: %d bytes (%d MiB)\n\n' $BOOT_FILES_SIZE $((BOOT_FILES_SIZE / 1048576))
printf '\t}\n\tsize = %s\n}' "$BOOT_FILES_SIZE" >> "$BOOT_CONFIG"

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
rm "$BOOT_CONFIG"
