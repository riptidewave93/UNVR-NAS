#!/bin/bash
set -e

scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Extract the goodies
${scripts_path}/ubnt-fw-parse.py "${root_path}/unifi-firmware/${firmware_filename}" "${build_path}/fw-extract/${firmware_filename%.bin}"

# Extract the squashfs rootfs
if ! [ -d "${build_path}/fw-extract/${BOARD}-rootfs" ]; then
    echo "Extracting unifi rootfs as root..."
    unsquashfs -f -d "${build_path}/fw-extract/${BOARD}-rootfs" "${build_path}/fw-extract/${firmware_filename%.bin}/rootfs.bin"
fi
