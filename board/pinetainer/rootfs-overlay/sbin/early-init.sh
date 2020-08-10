#!/bin/sh

# This script mount a overlay filesystem as a root filesystem, performs some minimal setup
# activites and then replaces itself by the actual init process in /sbin/init. Although these
# responsabilities are traditionally handled by a initial ramdisk, doing them in a script
# like this is simpler and faster for our purposes.

# The block device where the upper filesystem resides.
readonly UPPER_FS_DEVICE='/dev/mmcblk2p3'
# The mount options for the upper filesystem.
readonly UPPER_FS_MOUNT_OPTIONS='lazytime'
# The root overlay directory, inside of which the empty directories "upper", "lower" and
# "overlay" must be present to mount the upper filesystem, lower filesystem and the overlay,
# respectively.
readonly OVERLAY_DIRECTORY='/media/rootfs-overlay'
# The sysfs LED object that represents the LED to try to blink if an error occurs.
readonly ERROR_LED='/sys/class/leds/pine-h64:blue:status'

# Minimalistic PATH used by this script. The kernel doesn't initialize this.
readonly PATH='/bin:/sbin'

# Prints a fatal error message to the default console, and then tries to blink a LED
# forever to catch the attention of a human operator. This function doesn't return.
# $1: a textual description of the task that wasn't executed successfully.
# $2: the status code returned by the task.
show_fatal_error() {
	echo
	echo "! An error occurred while executing the following early init operation: $1"
	echo "  Status code: $?"

	# If the LED object directory doesn't exist, that may be because
	# sysfs is not mounted. Try to mount it
	if ! [ -d "$ERROR_LED" ]; then
		mount -t sysfs sysfs /sys
	fi

	# Blink the LED if we can, using a slow and unbalanced heartbeat pattern
	# that signals that things went wrong
	if [ -d "$ERROR_LED" ]; then
		echo 'pattern' > "$ERROR_LED/trigger"
		echo '1 2000 0 200 1 200 0 200 1 200 0 5000' > "$ERROR_LED/pattern"
	fi

	# Now unmount all mounted filesystems as a best-effort
	# (we might have mounted the upper filesystem)
	umount -a

	# Do nothing, forever
	while true; do
		sleep 65535
	done
}

# First mount the upper (rw) filesystem
if [ -n "$OPCIONES_MONTAJE_UPPER" ]; then
	mount -o "$UPPER_FS_MOUNT_OPTIONS,rw" "$UPPER_FS_DEVICE" "$OVERLAY_DIRECTORY/upper" >/dev/null 2>&1
else
	mount "$UPPER_FS_DEVICE" "$OVERLAY_DIRECTORY/upper" >/dev/null 2>&1
fi || show_fatal_error "$DISPOSITIVO_UPPER mount" $?

# Setup the needed folders in the upper filesystem
mkdir -p "$OVERLAY_DIRECTORY/upper/rootfs-overlay-files" || show_fatal_error 'upper files overlay directory creation' $?
mkdir -p "$OVERLAY_DIRECTORY/upper/work" || show_fatal_error 'overlay work directory creation' $?

# Montar el overlay
mount -t overlay \
-o "lowerdir=/,upperdir=$OVERLAY_DIRECTORY/upper/rootfs-overlay-files,workdir=$OVERLAY_DIRECTORY/upper/work" \
overlay "$OVERLAY_DIRECTORY/overlay" || show_fatal_error 'overlay mount' $?

# Bind mount /dev in the overlay root, and try to umount the original devtmpfs mount
mount --bind /dev "$OVERLAY_DIRECTORY/overlay/dev" || show_fatal_error 'bind mount /dev in overlay' $?
umount /dev || echo '! Couldn'\''t umount kernel mounted devtmpfs at /dev. Continuing anyway.'

# Now pivot the root directory like pivot_root(8) recommends. The current root directory
# is moved to the "lower" directory
cd "$OVERLAY_DIRECTORY/overlay" || show_fatal_error 'changing working directory to new root directory' $?
pivot_root . "${OVERLAY_DIRECTORY#/}/lower" || show_fatal_error 'pivot_root call' $?

# The mounts we have done at "overlay" and "upper" can only be accessed on the new root under
# "lower", because they were mounted in the previous root. Delete the now useless mount points
# for a tidier look
bin/rmdir "${OVERLAY_DIRECTORY#/}/overlay" 2>dev/null
bin/rmdir "${OVERLAY_DIRECTORY#/}/upper" 2>dev/null

# pivot_root(8) specifies that the root directory seen by current process may not change.
# Therefore, execute chroot to make sure it is updated, and then delegate to the real init
# process the system bringup
# shellcheck disable=SC2094
exec usr/sbin/chroot . /sbin/init "$@" <dev/console >dev/console 2>&1
