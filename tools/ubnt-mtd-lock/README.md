# ubnt-mtd-lock

A stupid basic kernel module to ensure we set /dev/mtd* as RO (fully) in our firmware. This is done to prevent users/bad actors from wiping your bootloader/Unifi EEPROM, which are required for your device to function!

## Building

    make -C ${kernel_source_dir} M=$PWD

## License

This code is licensed under the GNU General Public License, version 2. A copy of said license can be found at [https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html#SEC1](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html#SEC1)
