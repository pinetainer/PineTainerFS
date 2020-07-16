#!/bin/sh

# Kernel message level threshold: only the messages with a priority
# numerically lesser than (more important than) the specified
# will be shown in the main TTY
readonly MESSAGE_LEVEL_THRESHOLD=2

case "$1" in
	start)	printf 'Setting console kernel message level to %s: ' "$MESSAGE_LEVEL_THRESHOLD"
			printk_config=$(cut -f2,3,4 /proc/sys/kernel/printk 2>/dev/null)

			printf '%s       %s' "$MESSAGE_LEVEL_THRESHOLD" "$printk_config" > /proc/sys/kernel/printk 2>/dev/null &&
			printf 'OK\n' || \
			printf 'ERROR\n';;
	restart|reload)	;;
	*)		echo "Syntax: $0 {start|stop|restart|reload}"
			exit 1
esac
