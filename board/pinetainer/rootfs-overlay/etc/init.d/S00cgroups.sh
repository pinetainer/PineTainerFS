#!/bin/sh

# The directory where the cgroup2 hierarchy will be mounted
export readonly CGROUP_HIERARCHY_MOUNTPOINT=/sys/fs/cgroup

# The cgroup por system (i.e. non VM) processes
readonly SYSTEM_CGROUP=system

# The total number of CPU shares that will be distributed between the system and Pinetainers,
# via the cpu controller of cgroupsv2
readonly TOTAL_CPU_SHARES=1000

# The total number of IOPS shares that will be distributed between the system and Pinetainers,
# via the io controller of cgroupsv2
readonly TOTAL_IOPS_SHARES=1000

# System processes can use at least this percentage of the CPU time.
# 8% is equivalent to ~33% of a CPU core
readonly MINIMUM_SYSTEM_CPU_ALLOCATION=8

# System processes can use at least this percentage of the IO throughput
readonly MINIMUM_SYSTEM_IOPS_ALLOCATION=10

# The maximum amount of memory that processes in the system cgroup are allowed to use,
# in MiB, with a M suffix. If this threshold is exceeded, the OOM killer will kill processes
# cin the group to restore available memory. The processes in the cgroup will be put under
# high memory pressure when only less than the 25% of this memory is available
readonly MAXIMUM_SYSTEM_MEMORY=192M

# Limit the maximum number of processes that processes in the system cgroup can spawn
readonly MAXIMUM_SYSTEM_PIDS=512

# The file that represents high-level status information about the cgroups configuration
# in the system
readonly CGROUPS_INITIALIZED_STATUS_FILE=/run/cgroups_status

start() {
	printf 'Setting up cgroups: '

	if
	# Mount hierarchy and controllers
	mount -t cgroup2 cgroup2 "$CGROUP_HIERARCHY_MOUNTPOINT" && \
	echo '+cpu +io +memory +pids' > "$CGROUP_HIERARCHY_MOUNTPOINT/cgroup.subtree_control" && \
	mkdir "$CGROUP_HIERARCHY_MOUNTPOINT/$SYSTEM_CGROUP" && \
	# Move all proccesses to the system cgroup. This includes some kernel threads
	for pid in $(ps -A -o pid=); do
		echo "$pid" > "$CGROUP_HIERARCHY_MOUNTPOINT/$SYSTEM_CGROUP/cgroup.procs" || true
	done && \
	# Now setup the system cgroup controllers
	echo $(((TOTAL_CPU_SHARES * MINIMUM_SYSTEM_CPU_ALLOCATION) / 100)) > "$CGROUP_HIERARCHY_MOUNTPOINT/$SYSTEM_CGROUP/cpu.weight" && \
	echo $(((TOTAL_IOPS_SHARES * MINIMUM_SYSTEM_IOPS_ALLOCATION) / 100)) > "$CGROUP_HIERARCHY_MOUNTPOINT/$SYSTEM_CGROUP/io.bfq.weight" && \
	maximum_system_memory_megs="${MAXIMUM_SYSTEM_MEMORY%M}" && \
	high_system_memory_megs=$(((maximum_system_memory_megs * 3) / 4)) && \
	low_system_memory_megs=$((maximum_system_memory_megs / 2)) && \
	echo "${maximum_system_memory_megs}M" > "$CGROUP_HIERARCHY_MOUNTPOINT/$SYSTEM_CGROUP/memory.max" && \
	echo "${high_system_memory_megs}M" > "$CGROUP_HIERARCHY_MOUNTPOINT/$SYSTEM_CGROUP/memory.high" && \
	echo "${low_system_memory_megs}M" > "$CGROUP_HIERARCHY_MOUNTPOINT/$SYSTEM_CGROUP/memory.low" && \
	echo $MAXIMUM_SYSTEM_PIDS > "$CGROUP_HIERARCHY_MOUNTPOINT/$SYSTEM_CGROUP/pids.max" && \
	# Create cgroup status file
	touch "$CGROUPS_INITIALIZED_STATUS_FILE"
	then
		echo 'OK'
	else
		echo 'FAIL'
		return 1
	fi
}

# We read words from input files on purpose
# shellcheck disable=SC2013
stop() {
	printf 'Tearing down cgroups: '

	if if [ -f "$CGROUPS_INITIALIZED_STATUS_FILE" ]; then
		# Remove cgroup status file
		rm -f "$CGROUPS_INITIALIZED_STATUS_FILE" && \
		# Move all processes to the root cgroup
		for pid in $(ps -A -o pid=); do
			echo "$pid" > "$CGROUP_HIERARCHY_MOUNTPOINT/cgroup.procs" || true
		done && \
		# Remove all children cgroups
		find "$CGROUP_HIERARCHY_MOUNTPOINT"/* -depth -type d -exec rmdir {} \; && \
		# Remove all the controllers. This also resets their configuration
		shell_options_restore_cmds="$(set +o)" && \
		set -f && \
		for controller in $(cat "$CGROUP_HIERARCHY_MOUNTPOINT/cgroup.controllers"); do
			echo "-$controller" > "$CGROUP_HIERARCHY_MOUNTPOINT/cgroup.subtree_control"
		done && \
		eval "$shell_options_restore_cmds" && \
		# Umount the cgroup hierarchy
		umount "$CGROUP_HIERARCHY_MOUNTPOINT"
	fi; then
		echo 'OK'
	else
		echo 'FAIL'
		return 1
	fi
}

restart() {
	stop && start
}

case "$1" in
	start)			start;;
	stop)			stop;;
	restart|reload)	restart;;
	status)			[ -f "$CGROUPS_INITIALIZED_STATUS_FILE" ];;
	*)				echo "Usage: $0 {start|stop|restart|reload|status}"
					exit 1
esac
