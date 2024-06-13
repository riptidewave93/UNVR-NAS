#!/bin/bash
set -e

scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Exports baby
export PATH=${build_path}/toolchain/${toolchain_bin_path}:${PATH}
export GCC_COLORS=auto
export CROSS_COMPILE=${toolchain_cross_compile}
export ARCH=arm64

# Make our temp builddir for bluez so we can make bccmd
bluez_builddir=$(mktemp -d)
tar -xzf ${root_path}/downloads/${bluez_filename} -C ${bluez_builddir}

# Start with Bluez
cd ${bluez_builddir}/${bluez_repopath}

# If we have patches, apply them
if [[ -d ${root_path}/patches/bluez/ ]]; then
    for file in ${root_path}/patches/bluez/*.patch; do
        echo "Applying bluez patch ${file}"
        patch -p1 < ${file}
    done
fi

# Build bccmd from bluez
./bootstrap
./configure --disable-systemd \
    --enable-deprecated \
    --disable-library \
    --disable-cups \
    --disable-datafiles \
    --disable-manpages \
    --disable-pie \
    --disable-client \
    --disable-obex \
    --disable-udev \
    --build=x86_64-linux-gnu \
    --host=aarch64-none-linux-gnu \
    --target=aarch64-none-linux-gnu
make lib/bluetooth/hci.h lib/bluetooth/bluetooth.h lib/libbluetooth-internal.la tools/bccmd -j`getconf _NPROCESSORS_ONLN`

# Save our binary
mkdir -p ${build_path}/packages/bluez
mv ./tools/bccmd  ${build_path}/packages/bluez/

# Build ubnteeprom (our own tool)
mkdir -p ${build_path}/packages/ubnteeprom
env GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o ${build_path}/packages/ubnteeprom/ubnteeprom ${root_path}/tools/ubnteeprom/main.go

# Cleanup
cd - > /dev/null
rm -rf ${bluez_builddir}
