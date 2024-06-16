# ubnteeprom

A userspace tool to parse/read/render the EEPROM MTD partition on Unifi UNVR/UNVR Pro, and possibly other Dream Machine devices in the future.

## Purpose

This tool was created as a userspace replacement for the functions Unifi's ubnthal proprietary kernel module provides, by reporting most of the same information out as `/proc/ubnthal/*` as well as some output from `ubnt-tools id`.

The idea behind this is so we can get this repo off of using proprietary Unifi code as much as possible, so replacements for things are required. All code for this was reverse engineered and no unifi proprietary code was copied/used in the creation of this tool.

## Usage

Get similar output to `/proc/ubnthal/board`:

    ubnteeprom -board

Get similar output to `/proc/ubnthal/system.info`:

    ubnteeprom -systeminfo

Get similar output to `ubnt-tools id`:

    ubnteeprom -tools

Get a specfic value for a selected key in output, for example, `boardid`:

    ubnteeprom -board -key boardid

## Building

```
env GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o ubnteeprom main.go
```

## License

This code is licensed under the GNU General Public License, version 2. A copy of said license can be found at [https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html#SEC1](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html#SEC1)
