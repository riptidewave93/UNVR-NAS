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
cd "${build_path}/rootfs"
debootstrap --no-check-gpg --foreign --arch=${deb_arch} --include=apt-transport-https ${deb_release} "${build_path}/rootfs" ${deb_mirror}
cp /usr/bin/qemu-aarch64-static usr/bin/
chroot "${build_path}/rootfs" /debootstrap/debootstrap --second-stage

# Copy over our kernel modules and kernel from the FS image
# Note that in the future, we wanna use our own kernel, but the current GPL is way too old!!!!!
mv -f "${build_path}/fw-extract/${BOARD}-rootfs/lib/modules" "${build_path}/rootfs/lib"
cp "${build_path}/fw-extract/${firmware_filename%.bin}/kernel.bin" "${build_path}/rootfs/boot/uImage"

# Now, for the old kernel we built, pull in our extra modules we need! (depmod is done in bootstrap)
cp "${build_path}/kernel/kernel-modules/lib/modules/4.19.152-alpine-unvr/kernel/lib/zstd/zstd_compress.ko" "${build_path}/rootfs/lib/modules/4.19.152-alpine-unvr/extra/"
cp "${build_path}/kernel/kernel-modules/lib/modules/4.19.152-alpine-unvr/kernel/fs/btrfs/btrfs.ko" "${build_path}/rootfs/lib/modules/4.19.152-alpine-unvr/extra/"
cp "${build_path}/kernel/ubnt-mtd-lock.ko" "${build_path}/rootfs/lib/modules/4.19.152-alpine-unvr/extra/"

# Copy over our overlay if we have one
if [[ -d ${root_path}/overlay/${fs_overlay_dir}/ ]]; then
	echo "Applying ${fs_overlay_dir} overlay"
	cp -R ${root_path}/overlay/${fs_overlay_dir}/* ./
fi

# Hostname
echo "unvr-nas" > "${build_path}/rootfs/etc/hostname"
echo "127.0.1.1	unvr-nas" >> "${build_path}/rootfs/etc/hosts"

# Console settings
echo "console-common	console-data/keymap/policy	select	Select keymap from full list
console-common	console-data/keymap/full	select	us
" > "${build_path}/rootfs/debconf.set"

# Copy over stuff for ulcmd on UNVRPRO. this is hacky, but that's this ENTIRE repo for you
if [ "${BOARD}" == "UNVRPRO" ]; then
	mv "${build_path}/fw-extract/${BOARD}-rootfs/usr/bin/ulcmd" "${build_path}/rootfs/usr/bin/ulcmd" # LCD controller
	mv "${build_path}/fw-extract/${BOARD}-rootfs/usr/share/firmware" "${build_path}/rootfs/usr/share/" # LCD panel firmwares
	mkdir -p "${build_path}/rootfs/usr/lib/ubnt-fw/" # Home for ulcmd libraries
	for file in libgrpc++.so.1 libgrpc.so.10 libprotobuf.so.23 \
		libssl.so.1.1 libcrypto.so.1.1 libabsl*.so.20200923 libatomic.so.1; do
		cp -H ${build_path}/fw-extract/${BOARD}-rootfs/usr/lib/aarch64-linux-gnu/${file} "${build_path}/rootfs/usr/lib/ubnt-fw/"
	done
	# Now for the REAL JANK! patch ulcmd so it doesn't rely on /proc/ubnthal, so we can use our userspace tool ubnteeprom
	sed -i 's|/proc/ubnthal/system.info|/tmp/.ubnthal_system_info|g' "${build_path}/rootfs/usr/bin/ulcmd"
else
	# Remove our ld.so.conf.d as it's not needed for UVNR
	rm "${build_path}/rootfs/etc/ld.so.conf.d/ubnt.conf"
fi

# Copy over bluetooth firmware files
mkdir -p "${build_path}/rootfs/lib/firmware"
cp -R "${build_path}/fw-extract/${BOARD}-rootfs/lib/firmware/csr8x11" "${build_path}/rootfs/lib/firmware/" # LCD panel firmwares

# Install our bccmd we compiled (less we use from unifi the better)
cp -R "${build_path}/packages/bluez/bccmd" "${build_path}/rootfs/usr/bin"
chmod +x "${build_path}/rootfs/usr/bin/bccmd"

# Install our ubnteeprom tool
cp -R "${build_path}/packages/ubnteeprom/ubnteeprom" "${build_path}/rootfs/usr/bin"
chmod +x "${build_path}/rootfs/usr/bin/ubnteeprom"

# Kick off bash setup script within chroot
cp "${docker_scripts_path}/bootstrap/001-bootstrap" "${build_path}/rootfs/bootstrap"
chroot "${build_path}/rootfs" /bootstrap
rm "${build_path}/rootfs/bootstrap"

# Final cleanup
rm "${build_path}/rootfs/usr/bin/qemu-aarch64-static"
