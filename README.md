# UNVR-NAS

Firmware builder to convert your Unifi NVR Pro into an OpenMediaVault NAS appliance.

**This repo is still under heavy development and should be considered early alpha!**

## Supported Devices

* UNVR Pro

Note that the 1U UNVR is not currently supported!

## Usage

1. Download the required UNVRPro firmware, and place it in the unifi-firmware directory. Please see the README.md in that directory for more information.
2. Make sure your system has the required packages installed for this repo, which are:

    `docker-ce losetup wget sudo make qemu-user-static squashfs-tools`

3. Run the tool, and sit back and wait for it to do it's thing. Depending on your computer, this may take around an hour or so.

    `make`

4. Once done, you will have a built disk image in ./output

## Installation

Note that currently the install process requires UART to modify the u-boot env for booting.

1. Build the firmware image (follow the Usage section), and then throw it on an HDD/SSD formatted to ext4. Put said HDD in the UNVR Pro as the only hard drive.
2. Hook up UART to the UNVR Pro (4 pin header on the PCB near the DC Power Backup port)
3. Boot the UNVR Pro, and press esc twice when prompted to get to the u-boot shell
4. Run the following commands to update the kernel cmdline and save the changes:

    ```
    setenv rootfs /dev/boot2
    setenv bootargsextra boot=local rw
    saveenv
    ```

5. Boot into recovery (can use the below command)

    `run bootcmdrecovery`

6. Once recovery boots up, login with `ubnt:ubnt` or `root:ubnt`. You can also use telnet for this instead of UART if you prefer.
7. Mount your HDD with the firmware image, backup the Unifi firmware, and then flash our custom firmware to the EMMC. (below command example assumes your ext4 disk partition is at /dev/sda1)

    ```
    mount /dev/sda1 /mnt
    cd /mnt
    dd if=/dev/boot of=./unvrpro-emmc-backup.bin bs=4M
    gunzip debian-UNVRPRO.img.gz
    dd if=./debian-UNVRPRO.img of=/dev/boot bs=4M
    sync; reboot
    ```

8. At this point you can remove the HDD/SSD you used, and enjoy Debian 12 with OpenMediaVault on your UNVR Pro! Default login for OpenMediaVault is `admin:openmediavault`. SSH login information is `debian:debian`.

## Removal

To restore back to the factory UNVR-Pro firmware, you can do the following steps:

1. Hold the "reset" button on the front while powering on to boot into recovery
2. Once the display shows it's in recovery, telnet to the IP address. At the login prompt, login with `ubnt:ubnt` or `root:ubnt`.
3. Erase the uboot env, to remove our custom boot commands. This SHOULD be mtd1/mtd2, but **PLEASE VERIFY** first with `cat /proc/mtd` to prevent bricking your device!
4. Once the uboot env's are identified, erase them:

    ```
    dd if=/dev/zero of=/dev/mtd1
    dd if=/dev/zero of=/dev/mtd2
    ```

5. Next, erase the EMMC so all partitions are wiped:

    ```
    /sbin/parted -s -- /dev/boot mklabel gpt
    ```

6. Now you can use the Unifi Recovery WebUI to upload the firmware file, and restore your device.

## Known Issues

* Installation is Hard
    * Need to simplify the install process, this should be much easier once I can get latest GPL kernel source (no more uboot env stuff)
* Touchscreen
    * disks do not populate atm, cuz no grpc service mocking/replacing ustated
* OpenMediaVault
    * BTRFS does not work, period
        * No kernel module in UBNT kernel, need new kernel source and we can make so many things better...
* Fans
    * No service monitoring temps to adjust fan speed, so fans just stay at low spin from u-boot. Fans are on an i2c adt7475 controller
* Reset Button
    * Does literally nothing ATM, not sure if it's worth having it do something or not

## Disclaimer

Note that since prebuild Ubiquiti software is required for this tool to work, this repo will never have prebuilt images available. This is to prevent redistribution of Ubiquiti's IP, so please do not ask! Also, by using this repo you accept all risk associated with it including but not limited to voiding your warranty and releasing all parties from any liability associated with your device and this software.
