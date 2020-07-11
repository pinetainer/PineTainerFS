#!/bin/sh

. /usr/libexec/lxc/pinetainer-functions.sh

case $LXC_HOOK_SECTION in
	'net')
		case $LXC_HOOK_TYPE in
			'up')
				connectToVLAN "$LXC_NAME" "$LXC_NET_PEER"
				exit $?;;
		esac;;
esac
