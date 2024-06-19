#!/bin/bash

# ULCMD wrapper, used to start ulcmd on the UNVR Pro

# Ensure our tmp file with info is generated for our patched ulcmd
ubnteeprom -systeminfo > /tmp/.ubnthal_system_info

# Is ulcmd running already? if so, assume it was not done via systemd so let's
# kill and respawn as this is our systemd entry script for the service, and we
# need to have it foregrounded as we act as the "daemon" here.
if pidof -q ulcmd; then
    killall ulcmd
fi

# Start ulcmd
exec ulcmd
