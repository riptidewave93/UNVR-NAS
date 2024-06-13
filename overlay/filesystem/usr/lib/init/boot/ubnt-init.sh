#!/bin/bash

case "$1" in
    start)
        # Load our kernel modules
        /usr/sbin/modprobe ubnthal
        /usr/sbin/modprobe btrfs

        # Set our kernel panic timeout SUPER short so we reboot on crash
        echo 2 > /proc/sys/kernel/panic

        # Setup bluetooth hci0 device
        /usr/lib/init/boot/ubnt-bt.sh hci0
        ;;
    stop)
        # Tear down BT
        hciconfig hci0 down
        ;;
    *)
        echo "Invalid command $1"
        ;;
esac
