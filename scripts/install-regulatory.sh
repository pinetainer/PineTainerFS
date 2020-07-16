#!/bin/sh

# Base URL to download regulatory database files from.
readonly GIT_URL='https://git.kernel.org/pub/scm/linux/kernel/git/sforshee/wireless-regdb.git/plain/'
# The root directory where kernel configs will be located
readonly KERNEL_CONFIG_ROOT_SEARCH_DIR='board'
# Kconfig symbol to look for to deduce where the kernel expects firmware files to be.
readonly EXTRA_FIRMWARE_DIR_SYMBOL='EXTRA_FIRMWARE_DIR'
# The default firmware directory, where the kernel should expect to find firmware files
# unless explicitly configured otherwise.
readonly DEFAULT_FIRMWARE_DIR='/lib/firmware'

# Prints an error message to stderr and exit with an unsuccessful
# status code.
printError() {
	printf '\n' >&2
	printf '\033[1;91;40m! %s\n' "$1" >&2
	exit 1
}

# Gets the download URL for a certain file that is inside the Git
# repository specified in $GIT_URL.
# $1: the file to get the download URL of. It'll be printed to stdout.
buildDownloadUrl() {
	printf '%s%s' "$GIT_URL" "$1"
}

# Adds to the EXTRA_FIRMWARE_DIR variable a new directory to install regulatory
# files on. The directory is read from a kernel configuration file, which is taken
# into account to update the KERNEL_CONFIGS variable.
# $1: the kernel configuration file to read.
addFirmwareFolderFromConfig() {
	KERNEL_CONFIGS=$((KERNEL_CONFIGS + 1))

	while read -r config; do
		# Split line in two, using the = character as a token
		symbol=${config%%=*}
		value=${config#*=}

		if [ "$symbol" = "$EXTRA_FIRMWARE_DIR_SYMBOL" ]; then
			if ! echo "$EXTRA_FIRMWARE_DIRS" | grep -Fq "$value"; then
				printf '> %s sets %s to %s. Adding %s to the list of directories to install regulatory files to.\n' "$1" "$EXTRA_FIRMWARE_DIR_SYMBOL" "$value" "$value"
				EXTRA_FIRMWARE_DIRS=$(printf '%s\n%s' "$value" "$EXTRA_FIRMWARE_DIRS")
			fi
			folderFound=1

			break
		fi
	done < "$1"

	# If we parsed the file, but it didn't cointain a firmware directory (i.e. is a defconfig),
	# then append the default directory
	if [ -z "$folderFound" ]; then
		if ! echo "$EXTRA_FIRMWARE_DIRS" | grep -Fq "$DEFAULT_FIRMWARE_DIR"; then
			printf '> %s does not define %s. Adding %s to the list of directories to install regulatory files to.\n' "$1" "$EXTRA_FIRMWARE_DIR_SYMBOL" "$DEFAULT_FIRMWARE_DIR"
			EXTRA_FIRMWARE_DIRS=$(printf '%s\n%s' "$EXTRA_FIRMWARE_DIRS" "$DEFAULT_FIRMWARE_DIR")
		fi
	fi
}

# Downloads a file from buildDownloadUrl, saving it in the specified folder,
# only if it didn't exist or is newer than the previous one.
# $1: the filename to download from the Git repository defined in $GIT_URL.
# $2: the folder to save the file to.
downloadTo() {
	wget -Nc --no-if-modified-since -P "$2" "$(buildDownloadUrl "$1")" || printError "An error occured while downloading $1."
}

# Installs the regulatory database files in the directory where the kernel
# expects to find them for inclusion in the kernel image.
installRegulatoryFiles() {
	KERNEL_CONFIGS=0

	while IFS= read -r file; do
		addFirmwareFolderFromConfig "$file"
	done <<CMD
$(find "$KERNEL_CONFIG_ROOT_SEARCH_DIR" ! -name '*\\n*' -name 'linux.config')
CMD

	if [ -n "$EXTRA_FIRMWARE_DIRS" ]; then
		for directory in $EXTRA_FIRMWARE_DIRS; do
			# We have an empty directory at the end after appending
			if [ -n "$directory" ]; then
				printf '> Installing regulatory files to %s...\n\n' "$directory"
				(downloadTo 'regulatory.db' "$directory" && downloadTo 'regulatory.db.p7s' "$directory") || printError "Couldn't install database files."
			fi
		done
	fi

	if [ $KERNEL_CONFIGS -eq 0 ]; then
		echo '\033[1;91;40m! No kernel configuration files found. Nothing has been installed. Please check that the linux.config files are in your current working directory, or inside a subfolder.'
	else
		echo "> Regulatory database files installed for $KERNEL_CONFIGS kernel(s)."
	fi
}

installRegulatoryFiles
