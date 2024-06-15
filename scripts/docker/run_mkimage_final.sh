#!/bin/bash
set -e

scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Tempdir for root
GENIMAGE_ROOT=$(mktemp -d)

# setup and move bits
mkdir -p ${build_path}/final
cp ${build_path}/boot.ext4 ${build_path}/final/
cp ${build_path}/rootfs.ext4 ${build_path}/final/
cp ${root_path}/genimage_final.cfg ${build_path}/genimage.cfg

# We get to gen an image per board, YAY!
echo "Generating disk image"
genimage                         \
	--rootpath "${GENIMAGE_ROOT}"     \
	--tmppath "/tmp/genimage-initial-tmppath"    \
	--inputpath "${build_path}/final"  \
	--outputpath "${build_path}/final" \
	--config "${build_path}/genimage.cfg"
mv ${build_path}/final/emmc.img ${build_path}/final/debian-${BOARD}.img
gzip ${build_path}/final/debian-${BOARD}.img
rm -rf /tmp/genimage-initial-tmppath # Cleanup

# Cleanup
rm ${build_path}/final/boot.ext4 ${build_path}/final/rootfs.ext4 ${build_path}/genimage.cfg
