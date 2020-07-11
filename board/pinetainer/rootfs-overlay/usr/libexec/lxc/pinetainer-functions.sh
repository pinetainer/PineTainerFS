#!/bin/sh

# The ID of the container NIC to set its MAC
readonly NETWORK_ID=0
# The container VLAN configuration file. It
# associates container names with their VLAN
readonly CONTAINER_VLAN_FILE='/etc/lxc/vlan.conf'
# The VLAN to associate the container with if
# none was set in the configuration file
readonly DEFAULT_VLAN=4094
# The name of the volume group which will contain the
# containers' storage logical volumes
readonly VG_NAME='almacenamiento_contenedores'
# The space separated names of the devices that will
# be in the containers' storage VG
readonly PV_DEVICES='/dev/mmcblk2p6'
# The pool of thinly-provisioned storage to create on the VG.
# If empty, thinly-provisioned storage won't be used
readonly VG_POOL='pool0'
# The number of extents that will occupy the pool
# in the VG
readonly VG_POOL_EXTENTS='3435'
# The directory where logs of several operations will be saved
readonly LOG_DIR='/var/log/lxc/pinetainer'

# Keep /dev/null open for speed
exec 4>/dev/null

# Prints to standard output the available distributions for containers, with
# their releases and architectures, in RFC 4180 CSV format, with column headers.
# This operation contacts the LXC image server to retrieve an updated index, so it
# is expensive to call. Users are encouraged to cache its results. An empty or incomplete
# list might be returned if some error occured.
getImages() {
	/usr/share/lxc/templates/lxc-download --no-validate -l 2>&4 | awk 'BEGIN { OFS=","; print "\"distribution\",\"release\",\"arch\"" } $0 ~ /^--/ { ++headers; next } headers > 1 { gsub(/"/, "\"\"", $1); gsub(/"/, "\"\"", $2); gsub(/"/, "\"\"", $3); print "\"" $1 "\"", "\"" $2 "\"", "\"" $3 "\"" }' || true
}

# Obtains the value of a LXC container configuration parameter,
# as read in its configuration file.
# $1: the name of the container.
# $2: the key of the configuration item to get its value of.
getConfigParameter() {
	escapedName=$(printf '%s' "$2" | sed 's/\./\\./')
	sed -E -n "/^$escapedName ?= ?.*$/{s/^$escapedName ?= ?//;p;q}" "/var/lib/lxc/$1/config" | tail -1
}

# Establishes a LXC configuration parameter in the container
# configuration file. Changes in this file won't be applied
# until the container is started after the changes have been
# done.
# $1: the name of the container.
# $2: the name of the configuration parameter.
# $3: the value of the configuration parameter to set.
setConfigParameter() {
	# Replace the configuration parameter value if found, or
	# append it to the end of the configuration file if not found
	escapedName=$(printf '%s' "$2" | sed 's/\./\\./')
	sed -E -i "/^$escapedName/{s/=( ?).*/=\1$3/;h};\${x;/^$/{s//$2 = $3/;H};x}" "/var/lib/lxc/$1/config"
}

# Creates the VG that will contain LVs which will provide
# the containers' storage, if it was not already created.
createVG() {
	if vgdisplay -c | cut -d: -f1 | grep -E -c "^[ \t]*$VG_NAME$" >&4 2>&4; then
		# Do nothing, the VG was already created
		:
	else
		vgcreate "$VG_NAME" $PV_DEVICES && if [ -n "$VG_POOL" ]; then
			lvcreate -n "$VG_POOL" -l "$VG_POOL_EXTENTS" "$VG_NAME" && \
			lvconvert --type thin-pool "$VG_NAME/$VG_POOL"
		fi
	fi
}

# Assigns a very-likely-unique MAC address to the NETWORK_ID
# NIC of a container. The generated MAC address is the result
# of a one way function whose parameter is the container name.
# $1: the name of the container.
generateAndAssignMAC() {
	# Do a cheap hash (IEEE 802.3 Ethernet CRC32) on the container name
	containerNameCrc=$(printf '%s' "$1" | cksum)
	containerNameCrc=${containerNameCrc%% *}

	# Fake two more result bytes by doing ones' complement on the
	# resulting hash
	containerNameCrcExtra=$((containerNameCrc ^ 0xFFFFFFFF))
	containerNameCrcExtra=$((containerNameCrcExtra & 0x0000FFFF))

	# The first two bytes of the MAC address come from the extra
	# bytes. Just make sure that it is a unicast, locally administered
	# MAC (bits xxxxxx10 on the first byte)
	firstTwoMacBytes=$((containerNameCrcExtra & 0xFCFF))
	firstTwoMacBytes=$((firstTwoMacBytes | 0x0200))

	# Finally, combine both byte sources to get the NIC MAC
	mac=$(printf '%04x%08x' $firstTwoMacBytes $containerNameCrc | sed -E '1{s/([0-9a-f][0-9a-f])/&:/g;s/:$//}')

	# Replace the MAC address for the NETWORK_ID NIC
	setConfigParameter "$1" "lxc.net.$NETWORK_ID.hwaddr" "$mac"
}

# Configures the bridge the container is connected to with
# the VLAN the container should be in.
# $1: the name of the container.
# $2: the name of the host-side interface for the container
# (e.g. the other end or peer of the virtual Ethernet pair).
# $3 (optional): the contents of the $CONTAINER_VLAN_FILE file.
connectToVLAN() {
	# Read configuration records from the appropiate source
	if [ -z "$3" ]; then
		configFileRecords=$(cat "$CONTAINER_VLAN_FILE")
	else
		configFileRecords="$3"
	fi

	# Get container's VLAN, or the default one if none found
	IFS='
'	for record in $configFileRecords; do
		case $record in
			"#*") ;;
			"$1	*")
				containerVlan=${1##$1	*}
				containerVlan=${containerVlan##*	}
				break;;
			"$1 *")
				containerVlan=${1##$1 *}
				containerVlan=${containerVlan##* }
				break;;
		esac
	done

	if [ -z "$containerVlan" ]; then
		containerVlan="$DEFAULT_VLAN"
	fi

	# Change the bridge port configuration so its default VLAN
	# (PVID) for untagged outgoing packets is $containerVlan,
	# and only $containerVlan
	for vlan in $(sudo bridge vlan show dev "$2" | awk -F"[\t ]" 'NR > 1 && NF > 2 { print $3 }'); do
		bridge vlan del vid "$vlan" dev "$2"
	done && bridge vlan add vid "$containerVlan" dev "$2" pvid untagged
}

# Changes the value of a container cgroup state object, provided by
# a controller. If the container is running, the new value will be
# applied inmediately.
# $1: the container name.
# $2: the cgroup state object to set, in LXC notation. For example,
# "memory.limit_in_bytes".
# $3: the new value of the cgroup state object.
setContainerCgroupStateObject() {
	if [ "$(lxc-info -Hs "$1" 2>&4)" = 'RUNNING' ]; then
		lxc-cgroup -n "$1" "$2" "$3" 2>&4
	fi && setConfigParameter "$1" "lxc.cgroup.$2" "$3"
}

# Gets the value of a container cgroup state object, as set in the
# container configuration file.
# $1: the container name.
# $2: the cgroup state object to get its value of, in LXC notation.
getContainerCgroupStateObject() {
	getConfigParameter "$1" "lxc.cgroup.$2"
}

# Evaluates a shell function or command for each LXC container,
# i.e. runs it, until an error occurs or all the containers have been
# processed.
# $1: the shell function or command to evaluate. It will receive the
# container name as its single parameter.
forEachContainerDo() {
	IFS='
'	for container in $(lxc-ls); do
		eval "$1 \"$container\"" || break
	done
}

# Obtains the minimum percentage of total container CPU time that this container
# will be assigned when competing for other containers for a busy CPU.
# That is, if all the containers are using the system CPU fully, this
# percentage determines the time that will be dedicated to this container.
# The result is a percentage in the [0, 100] range multiplied by 100, to simulate
# two decimal positions precision, so the actual result range is an integer in
# [0, 10000].
# $1: the name of the container.
getContainerCpuUsagePercent() (
	totalShares=$(cat /sys/fs/cgroup/cpu/lxc/cpu.shares)
	containerShares=$(getContainerCgroupStateObject "$1" 'cpu.shares')
	containersWithSameShare=1

	accumulateContainersWithSameShare() {
		if [ "$(getContainerCgroupStateObject "$1" 'cpu.shares')" = "$containerShares" ]; then
			$((++containersWithSameShare))
		fi
	}
	forEachContainerDo 'accumulateContainersWithSameShare'

	printf '%d' $(((containerShares * 10000) / totalShares / containersWithSameShare))
)

setContainerCpuUsagePercent() (
	# 1. Contar número de contenedores.
	# 2. Hacer sumatoria de sharesContenedor / número contenedores.
	# 3. El cociente de sumatoria / sharesTotales es el porcentaje de tiempo ya ocupado por los contenedores.
	# El porcentaje parámetro será menor o igual a 1 - resultado.
	# 4. Asignar a cada contenedor, incluyendo el objeto, porcentajeDeseado * sharesTotales * número contenedores shares.
	# Los porcentajes de otros contenedores se guardarán con eval en una variable durante 3, obteniéndose con
	# getContainerCpuUsagePercent.
)

# Creates a Pinetainer container. This container is initialized with the
# default user namespace, resource limits and cgroup controller configuration.
# $1: the name of the container.
# $2: the size of the root filesystem of the container. It can be in any format
# that lxc-create accepts, such as "768M", "3G" or "27".
# $3: The distribution of the container (this is an argument passed to the download template).
# $4: the release of the distribution (this is an argument passed to the download template).
# $5: the architecture of the distribution (this is an argument passed to the download template).
createContainer() {
	createVG
	if [ -n "$VG_POOL" ]; then
		LXC_CACHE_PATH=/tmp/lxc lxc-create -l TRACE -o "$LOG_DIR/$1" -n "$1" -t download -Blvm --vgname "$VG_NAME" --thinpool "$VG_POOL" --fstype xfs --fssize "$2" --fsoptions '-m reflink=1' -- -d "$3" -r "$4" -a "$5" --no-validate --flush-cache
	else
		LXC_CACHE_PATH=/tmp/lxc lxc-create -l TRACE -o "$LOG_DIR/$1" -n "$1" -t download -Blvm --vgname "$VG_NAME" --fstype xfs --fssize "$2" --fsoptions '-m reflink=1' -- -d "$3" -r "$4" -a "$5" --no-validate --flush-cache
	fi && generateAndAssignMAC "$1"
}
