#!/bin/sh

# Estos alias aceleran ligeramente la operación,
# y evitan que se mezcle el prompt del terminal
# con el texto emitido por init. También implementan
# coldreboot.
alias reboot='reboot && exit'
alias coldreboot='touch /run/no-kexec-reboot && reboot'
alias halt='halt && exit'
alias shutdown='shutdown && exit'
alias poweroff='poweroff && exit'
