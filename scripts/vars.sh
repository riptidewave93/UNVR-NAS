#!/bin/bash

root_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
build_path="${root_path}/BuildEnv"

# Docker image name
docker_tag=unvr-nas:builder

# Expected UNVR Firmware(s) and hash(s)
UNVR_firmware_filename="df93-UNVR-4.0.18-45ee6a0c-32c9-4089-b4c0-3310196de7ae.bin"
UNVR_firmware_md5="8df8a9ea16c6e171a77cbb3bc096f1de"
UNVRPRO_firmware_filename="13b8-UNVRPRO-4.0.18-30952e81-b1e7-47fe-9bed-bd8d963d6048.bin"
UNVRPRO_firmware_md5="4a6d1abb862a3d54a6f5a122497114e3"

# Render our board out
fwfnvar="${BOARD}_firmware_filename"
firmware_filename="${!fwfnvar}"
fwmd5var="${BOARD}_firmware_md5"
firmware_md5="${!fwmd5var}"

# Toolchain
toolchain_url="https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz"
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
deb_mirror="http://ftp.us.debian.org/debian"
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
