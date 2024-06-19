#!/bin/bash

case "$1" in
    start)
        # Load our kernel modules
        /usr/sbin/modprobe ubnt-mtd-lock # Force our /dev/mtd* as RO
        /usr/sbin/modprobe btrfs

        # Set our kernel panic timeout SUPER short so we reboot on crash
        echo 2 > /proc/sys/kernel/panic

        # Setup bluetooth hci0 device
        /usr/lib/init/boot/ubnt-bt.sh hci0

        # If UNVR, turn on LED
        if [ -f "/sys/class/leds/ulogo_ctrl/pattern" ]; then
            # Set boot LED to blue
            # 2=white, 1=blue, 0=off, needs a value set with :x for ms
            echo 1:500 > /sys/class/leds/ulogo_ctrl/pattern
        fi
        ;;
    stop)
        # Tear down BT
        hciconfig hci0 down
        # LED shutdown on UNVR4 is done via systemd/system-shutdown/unifi-shutdown
        ;;
    *)
        echo "Invalid command $1"
        ;;
esac
