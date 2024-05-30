#!/bin/bash
set -e

scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Make our temp builddir outside of the world of mounts for SPEEDS
kernel_builddir=$(mktemp -d)
tar -xzf ${root_path}/downloads/${kernel_filename} -C ${kernel_builddir}

# Exports baby
export PATH=${build_path}/toolchain/${toolchain_bin_path}:${PATH}
export GCC_COLORS=auto
export CROSS_COMPILE=${toolchain_cross_compile}
export ARCH=arm64

# Here we go
cd ${kernel_builddir}/${kernel_filename%.tar.gz}

# If we have patches, apply them
if [[ -d ${root_path}/patches/kernel/ ]]; then
    for file in ${root_path}/patches/kernel/*.patch; do
        echo "Applying kernel patch ${file}"
        patch -p1 < ${file}
    done
fi

# Apply overlay if it exists
if [[ -d ${root_path}/overlay/${kernel_overlay_dir}/ ]]; then
    echo "Applying ${kernel_overlay_dir} overlay"
    cp -R ${root_path}/overlay/${kernel_overlay_dir}/* ./
fi

# Normally we would build a full kernel, but the old GPL doesn't work right with NICs and I don't
# want to debug a 2+ year old GPL source. Waiting for Unifi to release the lastest GPL code, and
# then we can fully move to our own custom kernel but for now we just use the old GPL to strip out
# some modules. This is why some lines below are commented out.

# Build as normal, with our extra version set to a timestamp
make ${kernel_config} 
make -j`getconf _NPROCESSORS_ONLN` EXTRAVERSION=-alpine-unvr # Build kernel and modules
#make -j`getconf _NPROCESSORS_ONLN` EXTRAVERSION=-alpine-unvr Image.gz # makes gzip image
make INSTALL_MOD_PATH=./modules-dir -j`getconf _NPROCESSORS_ONLN` EXTRAVERSION=-alpine-unvr modules_install # installs modules to dir
#mkimage -A arm64 -O linux -T kernel -C gzip -a 04080000 -e 04080000 -n "Linux-UNVR-NAS-$(date +%Y%m%d-%H%M%S)" -d ./arch/arm64/boot/Image.gz uImage

# Save our config
mkdir -p ${build_path}/kernel
make savedefconfig
mv defconfig ${build_path}/kernel/kernel_config

# Save our kernel(s) and libs
#cp ./arch/arm64/boot/Image.gz ${build_path}/kernel
#mv uImage ${build_path}/kernel
mv ./modules-dir ${build_path}/kernel/kernel-modules
