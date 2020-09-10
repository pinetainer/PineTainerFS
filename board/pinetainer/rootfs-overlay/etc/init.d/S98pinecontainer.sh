#!/bin/sh

# The program that will be used to launch Pinecontainers.
readonly PINECONTAINER_LAUNCH_PROGRAM=/usr/bin/pinecontainer-launch.sh

# The program that will be used to stop Pinecontainers.
readonly PINECONTAINER_STOP_PROGRAM=/usr/bin/pinecontainer-stop.sh

# The directory where Pinecontainer VMs configuration files reside.
readonly PINECONTAINER_CONFIG_FILES_DIR=/etc/pinecontainer

# The runtime data directory, where runtime data about VMs will be stored.
readonly RUNTIME_DATA_DIR=/run/pinecontainer

# The name of the LVM volume group where a logical volume for each Pinecontainer
# will be created.
readonly LVM_VOLUME_GROUP_NAME=pinecontainer_data

# The physical volumes that integrate the LVM volume group for Pinecontainer
# storage.
readonly LVM_PHYSICAL_VOLUMES=/dev/mmcblk2p6

start() {
	printf 'Starting Pinecontainers: '

	# Check whether the volume group exists. If not, create it
	if ! vgs --readonly --logonly -q "$LVM_VOLUME_GROUP_NAME" >/dev/null; then
		printf 'Creating LVM VG %s: ' "$LVM_VOLUME_GROUP_NAME"

		# We actually want to split and do globbing
		# shellcheck disable=SC2086
		if ! vgcreate "$LVM_VOLUME_GROUP_NAME" $LVM_PHYSICAL_VOLUMES >/dev/null; then
			echo ' ERROR'
			return 1
		else
			echo ' OK'
		fi
	fi

	# Make sure that the VG is available
	vgchange -ay "$LVM_VOLUME_GROUP_NAME" >/dev/null && \

	# Now launch the virtual machines with the launch program
	for vm_config_file in "$PINECONTAINER_CONFIG_FILES_DIR"/*.conf; do
		if [ -f "$vm_config_file" ]; then
			if "$PINECONTAINER_LAUNCH_PROGRAM" -v "$LVM_VOLUME_GROUP_NAME" -d "$RUNTIME_DATA_DIR" "$vm_config_file"; then
				echo " $vm_config_file: OK"
			else
				echo " $vm_config_file: ERROR. Code: $?" >&2
			fi
		fi
	done

	echo 'DONE'
}

stop() {
	printf 'Stopping Pinecontainers:'

	# Stop the virtual machines
	for vm in "$RUNTIME_DATA_DIR"/*; do
		if [ -f "$vm" ]; then
			vm_name="${vm#/run/pinecontainer/}"
			"$PINECONTAINER_STOP_PROGRAM" -s -m "$RUNTIME_DATA_DIR/$vm_name" "$vm_name"
		fi
	done

	# Now that virtual machines are (hopefully) shutdown, try to get rid of the volume group.
	# We ignore errors here because a rogue VM may still be using its logical volume anyway
	printf ' Deactivating LVM volume group:'
	if vgchange -an "$LVM_VOLUME_GROUP_NAME" >/dev/null 2>&1; then
		echo ' OK'
	else
		echo ' FAIL'
	fi

	echo 'DONE'
}

restart() {
	stop
	start
}

case "$1" in
	start)			start;;
	stop)			stop;;
	restart|reload)	restart;;
	*)				echo "Usage: $0 {start|stop|restart|reload}"
					exit 1
esac
