#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 00_prereq_check.sh"

# Check for required utils
for bin in losetup docker wget sudo unsquashfs; do
    if ! which ${bin} > /dev/null; then
        error_msg "${bin} is missing! Exiting..."
        exit 1
    fi
done

# Make sure loop module is loaded
if [ ! -d /sys/module/loop ]; then
    error_msg "Loop module isn't loaded into the kernel! This is REQUIRED! Exiting..."
    exit 1
fi

# Did we have a board set?
if [ -z "${BOARD}" ]; then
    echo "Error: BOARD is not set, so we don't know what we are building for! Exiting..."
    echo "Please review the README.md on usage!"
    exit 1
elif [ -z "${firmware_filename}" ]; then
    # Board is set, make sure it's a board we support
    echo "Error: Invalid BOARD value of ${BOARD}. Please review the README.md on usage!"
    exit 1
fi

# Validate FW is downloaded
if ! [ -f "${root_path}/unifi-firmware/${firmware_filename}" ]; then
    echo "Error: File ${firmware_filename} does not exist in ./unifi-firmware! Exiting..."
    exit 1
fi

# Does the checksum match?
file_md5=$(md5sum ${root_path}/unifi-firmware/${firmware_filename} | awk '{print $1}')
if [ "$file_md5" != "${firmware_md5}" ]; then
    echo "Error: File ${firmware_filename} does not have the expected checksum! This is either the wrong file, or it's corrupted. Exiting..."
    exit 1
fi

debug_msg "Finished 00_prereq_check.sh"
