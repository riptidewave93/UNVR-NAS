# UNVR-NAS

Firmware builder to convert your Unifi NVR/Unifi NVR Pro into an OpenMediaVault NAS appliance.

**This repo is still under heavy development and should be considered alpha!**

## Supported Devices

* UNVR
* UNVR Pro

## Disclaimer

Note that since prebuilt Ubiquiti software is currently required for this firmware, this repo doesn't have prebuilt images available. This is to prevent redistribution of Ubiquiti's IP, so please DO NOT ASK! Also, by using this repo you accept all risk associated with it including but not limited to voiding your warranty and releasing all parties from any liability associated with your device and this software. PROCEED AT YOUR OWN RISK!

## Usage

1. Download the required UNVR firmware for your device, and place it in the unifi-firmware directory. Please see the README.md in that directory for more information.
2. Make sure your linux system has the required packages installed for this repo, which are:

    `docker-ce losetup wget sudo make qemu-user-static squashfs-tools`

    Note that building from OSX/Windows is not supported. A Linux host is **REQUIRED**.

3. Run make with your board name set, and sit back and wait for the firmware image to build. Depending on your computer, this may take around an hour or so.

    For the UNVR: `BOARD=UNVR make`

    For the UNVR Pro: `BOARD=UNVRPRO make`

    * Also note that near the end of the image build process there will be some red text errors, but this is expected. This is due to the openmediavault install not being able to talk to systemd, as it's a debootstrap environment.

4. Once done, you will have a compressed disk image in ./output

## Installation

Note that currently the install process requires UART to modify the u-boot env for booting. In the future, if I can get the latest kernel GPL source, this will not be required.

1. MAKE SURE your UNVR/UNVR Pro is running the same Unifi firmware as referenced in the README.md in the unifi-firmware directory.
    * **Failure to do this can cause issues from the installation process not working, to the touch screen not working!**

2. Build the firmware image (follow the Usage section), and then throw it on an HDD/SSD formatted to ext4. Put said HDD in the UNVR/UNVR Pro as the only hard drive.

3. Hook up UART to the UNVR/UNVR Pro:

    On the UNVR, UART is located on the PCB behind the SFP+ cage, near the middle of the board (4 pins).

    On the UNVR Pro, UART is located on the PCB near the DC Power Backup port (4 pins).

4. Boot the UNVR/UNVR Pro, and in your UART console press Escape (Esc) twice when prompted to get to the u-boot shell. You only have 2 seconds to do this!
5. Run the following commands to update the kernel cmdline and save the changes:

    ```
    setenv rootfs PARTLABEL=rootfs
    setenv bootargsextra boot=local rw
    saveenv
    ```

6. Boot into recovery. This can be done using the command below, or by unplugging the UNVR/UNVR Pro, and holding the reset button for 10~ seconds as you power it back up.

    `run bootcmdrecovery`

7. Once recovery is booted, login with `ubnt:ubnt` or `root:ubnt`. Note this can be done either via UART shell, or if you want you can telnet into the IP address of your UNVR/UNVR Pro in recovery if you have it networked.

8. Mount your HDD with the firmware image and then flash our custom firmware to the EMMC/Storage. (Note the examples below expect your HDD with the firmware to be at /dev/sda)

    * UNVR:

        * Mount your disk to /mnt

            ```
            mount /dev/sda1 /mnt
            ```

        * Write the UNVR-NAS firmware image to the EMMC/Storage

            Note that if you have an older UNVR with the internal USB drive, you will need to replace `/dev/boot` with the path of your USB drive!

            ```
            gunzip /mnt/debian-UNVR.img.gz
            dd if=/mnt/debian-UNVR.img of=/dev/boot bs=4M
            sync
            reboot
            ```

    * UNVR Pro:

        * Mount your disk to /mnt

            ```
            mount /dev/sda1 /mnt
            ```

        * Write the UNVR-NAS firmware image to the EMMC/Storage

            ```
            gunzip /mnt/debian-UNVRPRO.img.gz
            dd if=/mnt/debian-UNVRPRO.img of=/dev/boot bs=4M
            sync
            reboot
            ```

9. At this point you can remove the HDD/SSD you used, and enjoy Debian 12 with OpenMediaVault on your UNVR/UNVR Pro! Default login for OpenMediaVault is `admin:openmediavault`. SSH login information is `debian:debian`. Please note that first boot may take a bit as cloud-init runs to finish the setup.

## Removal

To restore back to the factory UNVR/UNVR Pro firmware, you can do the following steps:

1. Hold the "reset" button on the front while powering on to boot into recovery
2. Once the device is in recovery mode, telnet to the IP address if the device (the UNVR Pro will display this on the touch screen). At the login prompt, login with `ubnt:ubnt` or `root:ubnt`.
3. Erase the uboot env, to remove our custom boot commands. This SHOULD be mtd1/mtd2, but **PLEASE VERIFY** first with `cat /proc/mtd` to prevent bricking your device! **DO NOT SKIP THIS STEP!** The output should match below, if not, **PLEASE DO NOT CONTINUE!**
    
    ```
    $ cat /proc/mtd
    dev:    size   erasesize  name
    mtd0: 001c0000 00001000 "u-boot"
    mtd1: 00010000 00001000 "u-boot env"
    mtd2: 00010000 00001000 "u-boot env redundant"
    mtd3: 00010000 00001000 "Factory"
    mtd4: 00010000 00001000 "EEPROM"
    mtd5: 01000000 00001000 "recovery kernel"
    mtd6: 00e00000 00001000 "config"
    ```

4. Once the uboot env's are identified, erase them to remove the setting overrides we added during install:

    ```
    dd if=/dev/zero of=/dev/mtd1
    dd if=/dev/zero of=/dev/mtd2
    ```

5. Next, erase the EMMC so all partitions are wiped:

    Note that if you have an older UNVR with the internal USB drive, you will need to replace `/dev/boot` with the path of your USB drive!

    ```
    /sbin/parted -s -- /dev/boot mklabel gpt
    ```

6. Now you can use the Unifi Recovery WebUI to upload the firmware file, and restore your device.

## Known Issues

* Installation is Hard
    * Need to simplify the install process, this should be much easier once I can get latest GPL kernel source (no more uboot env stuff)
* Reset Button
    * Only works to reboot the system, may wire this up to reset the WebUI password in OpenMediaVault down the road
