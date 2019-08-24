#!/bin/sh -f

# Base URL to download regulatory database files from.
readonly GIT_URL='https://git.kernel.org/pub/scm/linux/kernel/git/sforshee/wireless-regdb.git/plain/'
# Kconfig symbol to look for to deduce where the kernel expects firmware files to be.
readonly EXTRA_FIRMWARE_DIR_SYMBOL='EXTRA_FIRMWARE_DIR'
# The default firmware directory, where the kernel should expect to find firmware files
# unless explicitly configured otherwise.
readonly DEFAULT_FIRMWARE_DIR='/lib/firmware'

# Prints an error message to stderr and exit with an unsuccessful
# status code.
printError() {
	printf '\n' >&2
	printf '! %s\n' "$1" >&2
	exit 1
}

# Gets the download URL for a certain file that is inside the Git
# repository specified in $GIT_URL.
# $1: the file to get the download URL of. It'll be printed to stdout.
getDownloadUrl() {
	printf '%s%s' "$GIT_URL" "$1"
}

# Reads one character from stdin, representing an answer to a yes/no
# question. The answer is printed to stdout.
readYesNoAnswer() {
	sttyOld=$(stty -g)
	stty -icanon min 1

	printf '%s' "$(dd bs=1 count=1 2>/dev/null)"

	stty "$sttyOld"
}

# Asks a yes/no question to the user. A newline character is printed
# to stdout after the answer automatically, to prettify output. The
# answer is saved to the ANSWER variable.
# $1: the question text.
# $2: the default answer, if running in non-interactive mode (defaults to y).
askYesNoQuestion() {
	if [ "$INTERACTIVE" = '1' ]; then
		printf '%s' "$1"
		ANSWER=$(readYesNoAnswer)
		printf '\n'
	else
		# Assume default answer
		ANSWER=${2:-y}
	fi
}

# Adds to the EXTRA_FIRMWARE_DIR variable a new directory to install regulatory
# files on. The directory is read from a kernel configuration file, which is taken
# into account to update the KERNEL_CONFIGS variable.
# $1: the kernel configuration file to read.
addFirmwareFolderFromConfig() {
	KERNEL_CONFIGS=$((KERNEL_CONFIGS + 1))

	IFS='
'

	(cat "$1" || catError=1) | for config; do
		# Split line in two, using the = character as a token
		symbol=${config%%=*}
		value=${config#*=}

		if [ "$symbol" = "$EXTRA_FIRMWARE_DIR_SYMBOL" ]; then
			askYesNoQuestion $(printf '%s sets %s to %s. Install regulatory files there? (Y/n) ' "$1" "$EXTRA_FIRMWARE_DIR" "$value")

			if [ "$ANSWER" != 'n' -a "$ANSWER" != 'N' ]; then
				EXTRA_FIRMWARE_DIRS=$(printf '%s\n%s' "$value" "$EXTRA_FIRMWARE_DIRS")
				folderFound=1
			fi

			break
		fi
	done

	# If we parsed the file, but it didn't cointain a firmware directory (i.e. is a defconfig),
	# then append the default directory
	if [ -z "$folderFound" -a -z "$catError" ]; then
		askYesNoQuestion $(printf 'Install regulatory files in %s? (Y/n) ' "$DEFAULT_FIRMWARE_DIR")

		if [ "$ANSWER" != 'n' -a "$ANSWER" != 'N' ]; then
			EXTRA_FIRMWARE_DIRS=$(printf '%s\n%s' "$EXTRA_FIRMWARE_DIRS" "$DEFAULT_FIRMWARE_DIR")
		fi
	fi

	unset IFS
	unset folderFound
	unset catError
}


# Downloads a file from getDownloadUrl, saving it in the specified folder,
# only if it didn't exist or is newer than the previous one.
# $1: the filename to download from the Git repository defined in $GIT_URL.
# $2: the folder to save the file to.
downloadTo() {
	wget -Nc --no-if-modified-since -P "$2" "$(getDownloadUrl $1)" || printError "An error occured while downloading $1."
	return $?
}

# Installs the regulatory database files in the directory where the kernel
# expects to find them for inclusion in the kernel image.
installRegulatoryFiles() {
	KERNEL_CONFIGS=0

	for file in $(find -type f -name 'linux.config'); do
		addFirmwareFolderFromConfig "$file"
	done

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
		echo '- No kernel configuration files found. Nothing has been installed. Please check that the linux.config files are in your current working directory, or inside a subfolder.'
	else
		echo "- Regulatory database files installed for $KERNEL_CONFIGS kernel/s."
	fi
}

# Parse command line arguments
INTERACTIVE=1
while getopts 'n' option; do
	case $option in
		n) unset INTERACTIVE;;
		?) printf 'Usage: %s [-n]\n\t-n: skips asking the user for confirmation to install regulatory database files.\n' "$0"
		   exit 2;;
	esac
done

installRegulatoryFiles
