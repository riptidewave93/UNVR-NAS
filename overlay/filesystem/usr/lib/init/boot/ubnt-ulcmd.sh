#!/bin/bash

# ULCMD wrapper, used to start ulcmd on the UNVR Pro, or setup the status LED on the UNVR-4

case "$(ubnteeprom -systeminfo -key shortname)" in
    "UNVRPRO")
        # Is ulcmd running already? if so, assume it was not done via systemd so let's
        # kill and respawn as this is our systemd entry script for the service, and we
        # need to have it foregrounded as we act as the "daemon" here.
        if ! pidof -q ulcmd; then
            killall ulcmd
        fi
        # Restart ulcmd
        exec ulcmd
        ;;
    "UNVR4")
        # TODO: LED setup (2=white, 1=blue) against /sys/class/leds/ulogo_ctrl
        # Start our "daemon" loop so systemd stays happy
        while true; do
            sleep 3600
        done
        ;;
    *)
        exit 1
        ;;
esac
