#!/bin/sh

# Some useful aliases for shutdown and restart commands
alias reboot='reboot && exit'
alias coldreboot='touch /run/no-kexec-reboot && reboot'
alias halt='halt && exit'
alias shutdown='shutdown && exit'
alias poweroff='poweroff && exit'
