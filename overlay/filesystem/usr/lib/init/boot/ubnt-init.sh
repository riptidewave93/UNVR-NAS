#!/bin/bash

# Load our kernel modules
/usr/sbin/modprobe ubnthal
/usr/sbin/modprobe btrfs

# Set our kernel panic timeout SUPER short so we reboot on crash
echo 2 > /proc/sys/kernel/panic
