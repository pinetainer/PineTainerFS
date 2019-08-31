#!/bin/sh

# Estos alias aceleran ligeramente la operación,
# y evitan que se mezcle el prompt del terminal
# con el texto emitido por init
alias reboot='reboot && exit'
alias halt='halt && exit'
alias shutdown='shutdown && exit'
alias poweroff='poweroff && exit'
