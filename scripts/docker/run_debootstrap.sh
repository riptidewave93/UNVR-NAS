#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Exports
export PATH=${build_path}/toolchain/${toolchain_bin_path}:${PATH}
export GCC_COLORS=auto
export CROSS_COMPILE=${toolchain_cross_compile}
export ARCH=arm64
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# CD into our rootfs mount, and starts the fun!
cd ${build_path}/rootfs
debootstrap --no-check-gpg --foreign --arch=${deb_arch} --include=apt-transport-https ${deb_release} ${build_path}/rootfs ${deb_mirror}
cp /usr/bin/qemu-aarch64-static usr/bin/
chroot ${build_path}/rootfs /debootstrap/debootstrap --second-stage

# Copy over our kernel modules and kernel
mv -f "${build_path}/fw-extract/rootfs/lib/modules" ${build_path}/rootfs/lib
cp "${build_path}/fw-extract/kernel.bin" "${build_path}/rootfs/boot/uImage"

# Copy over our overlay if we have one
if [[ -d ${root_path}/overlay/${fs_overlay_dir}/ ]]; then
	echo "Applying ${fs_overlay_dir} overlay"
	cp -R ${root_path}/overlay/${fs_overlay_dir}/* ./
fi

# Apply our part UUIDs to fstab
sed -i "s|BOOTUUIDPLACEHOLDER|$(blkid -o value -s UUID ${build_path}/boot.ext4)|g" ${build_path}/rootfs/etc/fstab
sed -i "s|ROOTUUIDPLACEHOLDER|$(blkid -o value -s UUID ${build_path}/rootfs.ext4)|g" ${build_path}/rootfs/etc/fstab

# Hostname
echo "${distrib_name}" > ${build_path}/rootfs/etc/hostname
echo "127.0.1.1	${distrib_name}" >> ${build_path}/rootfs/etc/hosts

# Console settings
echo "console-common	console-data/keymap/policy	select	Select keymap from full list
console-common	console-data/keymap/full	select	us
" > ${build_path}/rootfs/debconf.set

# Copy over stuff for ulcmd, this is hacky, but that's this ENTIRE repo for you
mv "${build_path}/fw-extract/rootfs/lib/systemd/system/ulcmd.service" "${build_path}/rootfs/lib/systemd/system/ulcmd.service"
mv "${build_path}/fw-extract/rootfs/usr/bin/ulcmd" "${build_path}/rootfs/usr/bin/ulcmd" # LCD controller
mv "${build_path}/fw-extract/rootfs/usr/share/firmware" "${build_path}/rootfs/usr/share/" # LCD panel firmwares
mkdir -p "${build_path}/rootfs/usr/lib/ubnt-fw/" # Home for ulcmd libraries
for file in libgrpc++.so.1 libgrpc.so.10 libprotobuf.so.23 \
	libssl.so.1.1 libcrypto.so.1.1 libabsl*.so.20200923 libatomic.so.1; do
	cp -H ${build_path}/fw-extract/rootfs/usr/lib/aarch64-linux-gnu/${file} "${build_path}/rootfs/usr/lib/ubnt-fw/"
done
sed -i 's|Type=simple|Type=simple\nEnvironment="LD_LIBRARY_PATH=/usr/lib/ubnt-fw"|g' "${build_path}/rootfs/lib/systemd/system/ulcmd.service" # Add library path

# Kick off bash setup script within chroot
cp ${docker_scripts_path}/bootstrap/001-bootstrap ${build_path}/rootfs/bootstrap
chroot ${build_path}/rootfs /bootstrap
rm ${build_path}/rootfs/bootstrap

# Final cleanup
rm ${build_path}/rootfs/usr/bin/qemu-aarch64-static