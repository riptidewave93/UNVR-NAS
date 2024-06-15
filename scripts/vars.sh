#!/bin/bash

root_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
build_path="${root_path}/BuildEnv"

# Docker image name
docker_tag=unvr-nas:builder

# Expected UNVR Firmware(s) and hash(s)
UNVR_firmware_filename="7f7c-UNVR-4.0.5-1d4b9c7d-926b-4ef4-88c6-23978c2455a8.bin"
UNVR_firmware_md5="3bab9336619125e7fe6e4af7484a79dc"
UNVRPRO_firmware_filename="b0a3-UNVRPRO-4.0.5-f221e29e-3405-4cb9-8d13-0f117d9cc3a1.bin"
UNVRPRO_firmware_md5="f6aec555fa79c4e083168ec2aac4a71a"

# Render our board out
fwfnvar="${BOARD}_firmware_filename"
firmware_filename="${!fwfnvar}"
fwmd5var="${BOARD}_firmware_md5"
firmware_md5="${!fwmd5var}"

# Toolchain
toolchain_url="https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz"
toolchain_filename="$(basename ${toolchain_url})"
toolchain_bin_path="${toolchain_filename%.tar.xz}/bin"
toolchain_cross_compile="aarch64-none-linux-gnu-"

# Kernel
kernel_src="https://github.com/fabianishere/udm-kernel/archive/refs/heads/master.tar.gz"
kernel_filename="udm-kernel-master.tar.gz"
kernel_config="alpine_v2_defconfig"
kernel_overlay_dir="kernel"

# Genimage
genimage_src="https://github.com/pengutronix/genimage/releases/download/v16/genimage-16.tar.xz"
genimage_filename="$(basename ${genimage_src})"
genimage_repopath="${genimage_filename%.tar.xz}"

# bluez
bluez_src="https://github.com/bluez/bluez/archive/refs/tags/5.55.tar.gz"
bluez_filename="bluez-$(basename ${bluez_src})"
bluez_repopath="${bluez_filename%.tar.gz}"

# Distro
distrib_name="debian"
#deb_mirror="http://ftp.us.debian.org/debian"
deb_mirror="http://debian.uchicago.edu/debian"
deb_release="bookworm"
deb_arch="arm64"
fs_overlay_dir="filesystem"

debug_msg () {
    BLU='\033[0;32m'
    NC='\033[0m'
    printf "${BLU}${@}${NC}\n"
}

error_msg () {
    BLU='\033[0;31m'
    NC='\033[0m'
    printf "${BLU}${@}${NC}\n"
}
