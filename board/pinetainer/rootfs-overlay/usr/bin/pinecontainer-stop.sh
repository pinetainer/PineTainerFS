#!/bin/sh

# Does a best effort attempt to stop a Pinecontainer virtual machine.
# Parameters:
# -m monitor_path: the path where the QEMU monitor Unix sockets reside.
# $1: the name of the Pinecontainer.

# The maximum time that this script will wait for a Pinecontainer to stop, in seconds
readonly SHUTDOWN_WAIT_TIME=30

while getopts sm: option; do
	case $option in
		s)		INITD_SERVICE_MODE=1;;
		m)		VM_MONITOR_SOCKET_PATH="$OPTARG";;
		?|*)	printf "Syntax: %s [-s] -m monitor_path pinecontainer_name\n" "$0" >&2
				exit 1;;
	esac
done

if [ -z "$VM_MONITOR_SOCKET_PATH" ]; then
	echo "$0: the VM monitor Unix socket path is empty or unset" >&2
	exit 2
fi

shift $((OPTIND - 1)) 2>/dev/null
if [ -z "$1" ]; then
	echo "$0: the name of the Pinecontainer cannot be empty or unset" >&2
	exit 3
fi

# Compute the monitor file path
VM_MONITOR_FILE="$VM_MONITOR_SOCKET_PATH/monitor.sock"

# Send shutdown command to the QEMU monitor and wait for the VM to stop.
# On the guest, this is visible as an ACPI shutdown request, like if a physical
# shutdown button was pressed
if echo 'system_powerdown' | socat -u - UNIX-CONNECT:"$VM_MONITOR_FILE"; then
	if [ -n "$INITD_SERVICE_MODE" ]; then
		printf '\n %s' "$VM_MONITOR_FILE"
	else
		printf "ACPI shutdown request sent to %s. Waiting for VM to power down" "$VM_MONITOR_FILE"
	fi

	elapsed_seconds=0
	while sleep 1; [ $elapsed_seconds -lt $SHUTDOWN_WAIT_TIME ]; do
		# Consider shutdown successful once the VM stops listening to the socket
		# (i.e. its QEMU process exits)
		if ! socat -u - UNIX-CONNECT:"$VM_MONITOR_FILE" </dev/null >/dev/null 2>&1; then
			break
		fi

		printf '.'
	done

	if [ $elapsed_seconds -ge $SHUTDOWN_WAIT_TIME ]; then
		echo ' FAIL'
	else
		echo ' OK'
	fi
else
	echo " $VM_MONITOR_FILE: shutdown command send failed. Is the VM running, and its Unix socket listening?" >&2
fi
