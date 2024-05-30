#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 03_docker.sh"

# Start with things we can do now
if [ ! -d ${build_path}/toolchain ]; then
    debug_msg "Setting up the toolchain for docker..."
    mkdir -p ${build_path}/toolchain
    tar -xf ${root_path}/downloads/${toolchain_filename} -C ${build_path}/toolchain
fi

if [ ! -d ${build_path}/kernel ]; then
    debug_msg "Docker: Building Kernel..."
    docker run --ulimit nofile=1024 --rm -v "${root_path}:/repo:Z" -it ${docker_tag} /repo/scripts/docker/build_kernel.sh
fi

debug_msg "Doing safety checks... please enter your password for sudo if prompted..."
# Before we do anything, make our dirs, and validate they are not mounted atm. If they are, exit!
if mountpoint -q ${build_path}/rootfs/boot; then
    error_msg "ERROR: ${build_path}/rootfs/boot is mounted before it should be! Cleaning up..."
    sudo umount ${build_path}/rootfs/boot
fi
if mountpoint -q ${build_path}/rootfs; then
    error_msg "ERROR: ${build_path}/rootfs is mounted before it should be! Cleaning up..."
    sudo umount ${build_path}/rootfs
fi

# Validate we don't have image files yet, because if we do, they may be mounted, and
# that would be REAL BAD if we overwrite em
if [ -f ${build_path}/boot.ext4 ]; then
    error_msg "ERROR: ${build_path}/boot.ext4 exists already! Cleaning up..."
    rm -f ${build_path}/boot.ext4
fi
if [ -f ${build_path}/rootfs.ext4 ]; then
    error_msg "ERROR: ${build_path}/rootfs.ext4 exists already! Cleaning up..."
    rm -f ${build_path}/rootfs.ext4
fi

debug_msg "Docker: Generating rootfs and boot partitions..."
docker run --ulimit nofile=1024 --rm -v "${root_path}:/repo:Z" -it ${docker_tag} /repo/scripts/docker/run_mkimage_initial.sh

debug_msg "Note: You might be asked for your password for losetup and mounting of said loopback devices since sudo is used..."

debug_msg "Mounting generated block files for use with docker..."
# Mount our loopbacks
boot_loop_dev=$(sudo losetup -f --show ${build_path}/boot.ext4)
rootfs_loop_dev=$(sudo losetup -f --show ${build_path}/rootfs.ext4)

# And now mount them to the dirs :)
mkdir -p ${build_path}/rootfs
sudo mount -t ext4 ${rootfs_loop_dev} ${build_path}/rootfs
sudo mkdir -p ${build_path}/rootfs/boot
sudo mount -t ext4 ${boot_loop_dev} ${build_path}/rootfs/boot

# Remove stupid placeholder files -_-
sudo rm -f ${build_path}/rootfs/placeholder ${build_path}/rootfs/boot/placeholder

# SAFETY NET - trap it, even tho we have makefile with set -e
debug_msg "Docker: debootstraping..."
trap "sudo umount ${build_path}/rootfs/boot; sudo umount ${build_path}/rootfs; sudo losetup -d ${boot_loop_dev}; sudo losetup -d ${rootfs_loop_dev}" SIGINT SIGTERM
docker run --ulimit nofile=1024 --rm --privileged --cap-add=ALL -v /dev:/dev -v "${root_path}:/repo:Z" -it ${docker_tag} /repo/scripts/docker/run_debootstrap.sh

debug_msg "Note: You might be asked for your password for losetup and umount since we are cleaning up mounts..."
debug_msg "Cleaning up..."
sudo umount ${build_path}/rootfs/boot
sudo umount ${build_path}/rootfs
sudo losetup -d ${boot_loop_dev}
sudo losetup -d ${rootfs_loop_dev}
rm -rf ${build_path}/rootfs

debug_msg "Finished 03_docker.sh"
