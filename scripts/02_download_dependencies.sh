#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 02_download_dependencies.sh"

# Make sure our BuildEnv dir exists
if [ ! -d ${root_path}/downloads ]; then
    mkdir ${root_path}/downloads
fi

# Toolchain
if [ ! -f ${root_path}/downloads/${toolchain_filename} ]; then
    debug_msg "Downloading toolchain..."
    wget ${toolchain_url} -P ${root_path}/downloads
fi

# Kernel
if [ ! -f ${root_path}/downloads/${kernel_filename} ]; then
    debug_msg "Downloading Kernel..."
    wget ${kernel_src} -O ${root_path}/downloads/${kernel_filename}
fi

# Bluez
if [ ! -f ${root_path}/downloads/${bluez_filename} ]; then
    debug_msg "Downloading Package Bluez..."
    wget ${bluez_src} -O ${root_path}/downloads/${bluez_filename}
fi

debug_msg "Finished 02_download_dependencies.sh"
