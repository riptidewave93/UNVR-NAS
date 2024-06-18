#!/bin/bash

root_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
build_path="${root_path}/BuildEnv"

# Docker image name
docker_tag=unvr-nas:builder

# Expected UNVR Firmware(s) and hash(s)
UNVR_firmware_filename="62f6-UNVR-4.0.6-19610d35-cd43-4844-ae5e-5420d6ff6279.bin"
UNVR_firmware_md5="dc2e1693fe44aae8437f8ebcd8f0c6c1"
UNVRPRO_firmware_filename="19bf-UNVRPRO-4.0.6-6dd303cb-cb6d-4904-a8ee-ef6e5353016d.bin"
UNVRPRO_firmware_md5="84476cd12b90ab8c5344d4ff66211b1b"

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
