package main

import (
	"encoding/hex"
	"flag"
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"
)

// Type for device map
type UBNTSysMap struct {
	name, shortname, cpu, sysid string
}

var UBNTDeviceMap = []UBNTSysMap{
	{
		name:      "Unifi-NVR-PRO",
		shortname: "UNVRPRO",
		cpu:       "AL324V2",
		sysid:     "ea20",
	},
	{
		name:      "UniFi-NVR-4",
		shortname: "UNVR4",
		cpu:       "AL324V2",
		sysid:     "ea16",
	},
	{
		name:      "UniFi-NVR-4",
		shortname: "UNVR4",
		cpu:       "AL324V2",
		sysid:     "ea1a",
	},
}

type UBNT_Return_Values struct {
	name, value string
}

// Store our board vars
var UBNT_Board_Vars = []string{
	"format",
	"version",
	"boardid",
	"vendorid",
	"bomrev",
	"hwaddrbbase",
	"EthMACAddrCount",
	"WiFiMACAddrCount",
	"BtMACAddrCount",
	"regdmn[0]",
	"regdmn[1]",
	"regdmn[2]",
	"regdmn[3]",
	"regdmn[4]",
	"regdmn[5]",
	"regdmn[6]",
	"regdmn[7]",
}

// Store our systeminfo vars
var UBNT_SystemInfo_Vars = []string{
	// "cpu",
	// "cpuid",
	// "flashSize",
	// "ramsize",
	"vendorid",
	"systemid",
	// "shortname",
	"boardrevision",
	"serialno",
	// "manufid",
	// "mfgweek",
	// "qrid",
	// eth*.macaddr (generated mac's for all eth interfaces)
	// "device.hashid",
	// "device.anonid",
	// "bt0.macaddr",
	"regdmn[]",
	// "cpu_rev_id",
}

// Store our ubnt-tools id vars
var UBNT_Tools_vars = []string{
	"board.sysid",
	"board.serialno",
	"board.bom",
}

// Type for EEPROM structure
type EEPROM_Value struct {
	name, description, vtype string
	offset, length           int64
}

// Build our BOARD eeprom structure
var EEPROM = []EEPROM_Value{
	// START BOARD DATA
	{
		name:        "format",
		description: "EEPROM Format",
		offset:      0x800C,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "version",
		description: "EEPROM Version",
		offset:      0x800E,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "boardid",
		description: "Board Identifier (bomrev+model identifier)",
		offset:      0x8012,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "vendorid",
		description: "Vendor Identifier",
		offset:      0x8010,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "bomrev",
		description: "Bill of Materials Revision",
		offset:      0x8014,
		length:      0x4,
		vtype:       "hex",
	},
	{
		name:        "hwaddrbbase",
		description: "Base Mac Address for Device",
		offset:      0x8018,
		length:      0x6,
		vtype:       "hexmac",
	},
	{
		name:        "EthMACAddrCount",
		description: "Number of MAC addresses for ethernet interfaces",
		offset:      0x801E,
		length:      0x1,
		vtype:       "hexint",
	},
	{
		name:        "WiFiMACAddrCount",
		description: "Number of MAC addresses for WiFi interfaces",
		offset:      0x801F,
		length:      0x1,
		vtype:       "hexint",
	},
	{
		name:        "BtMACAddrCount",
		description: "Number of MAC addresses for Bluetooth interfaces",
		offset:      0x8070,
		length:      0x1,
		vtype:       "hexint",
	},
	{
		name:        "regdmn[0]",
		description: "Region Domain 0",
		offset:      0x8020,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "regdmn[1]",
		description: "Region Domain 1",
		offset:      0x8022,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "regdmn[2]",
		description: "Region Domain 2",
		offset:      0x8024,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "regdmn[3]",
		description: "Region Domain 3",
		offset:      0x8026,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "regdmn[4]",
		description: "Region Domain 4",
		offset:      0x8028,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "regdmn[5]",
		description: "Region Domain 5",
		offset:      0x802A,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "regdmn[6]",
		description: "Region Domain 6",
		offset:      0x802C,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "regdmn[7]",
		description: "Region Domain 7",
		offset:      0x802E,
		length:      0x2,
		vtype:       "hex",
	},
	// END BOARD DATA
	// START SYSTEM INFO
	// cpu
	// cpuid
	// flashSize (this is static in unifi's kernel module -_-)
	// ramsize
	{
		name:        "vendorid",
		description: "Vendor Identifier",
		offset:      0x8010,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "systemid",
		description: "Device Model/Revision Identifier",
		offset:      0xC,
		length:      0x2,
		vtype:       "hex",
	},
	// shortname (we may wanna map boardid for this)
	{
		name:        "boardrevision",
		description: "Board Revision for the device",
		offset:      0x13,
		length:      0x1,
		vtype:       "hextobase10",
	},
	{
		name:        "serialno",
		description: "Serial Number",
		offset:      0x0,
		length:      0x6,
		vtype:       "hex",
	},
	// manufid
	// mfgweek
	// qrid
	// eth*.macaddr (generated mac's for all eth interfaces)
	// device.hashid
	// device.anonid
	// bt0.macaddr (generated bt mac)
	{
		name:        "regdmn[]",
		description: "Region Domain",
		offset:      0x8020,
		length:      0x10,
		vtype:       "hex",
	},
	// cpu_rev_id
	// END SYSTEM INFO
	// START UBNT TOOLS ID
	{
		name:        "board.sysid",
		description: "Device Model/Revision Identifier",
		offset:      0xC,
		length:      0x2,
		vtype:       "hex",
	},
	// board.name (handled by UBNTDeviceMap)
	// board.shortname (handled by UBNTDeviceMap)
	// board.subtype
	// board.reboot # Time (s)
	// board.upgrade # Time (s)
	// board.cpu.id
	// board.uuid
	{
		name:        "board.bom",
		description: "Board Bill of Materials Revision Code",
		offset:      0xD024,
		length:      0xC,
		vtype:       "str",
	},
	// board.hwrev
	{
		name:        "board.serialno",
		description: "Serial Number",
		offset:      0x0,
		length:      0x6,
		vtype:       "hex",
	},
	// board.qrid
	// END UBNT TOOLS ID
}

func check(e error) {
	if e != nil {
		if strings.Contains(e.Error(), "encoding/hex: invalid byte:") {
			fmt.Printf("Error: Unable to parse hex, please check your input.\n")
		} else if strings.Contains(e.Error(), "EOF") {
			fmt.Printf("Error: Unable to read contents from EEPROM/file.\n")
		} else if strings.Contains(e.Error(), "encoding/hex: odd length hex string") {
			fmt.Printf("Error: Incorrect length of input. Please try again.\n")
		} else {
			fmt.Printf("Fatal Error!!! ")
			panic(e)
		}
		os.Exit(1)
	}
}

func eeprom_read(vl []EEPROM_Value, f *os.File, key string) string {
	var offs, leng int64
	var vtype string

	// Lookup our item
	for _, v := range vl {
		if v.name == key {
			offs = v.offset
			leng = v.length
			vtype = v.vtype
			break
		}
	}

	// Make sure we found it
	if (offs == 0) && (leng == 0) {
		fmt.Printf("Error: Invalid key %s!\n", key)
		os.Exit(1)
	}

	// Seek our file
	_, err := f.Seek(offs, 0)
	check(err)

	// Make var and read into it
	b2 := make([]byte, leng)
	_, err = f.Read(b2)
	check(err)

	// Format as needed depending on type
	switch vtype {
	case "hexmac":
		// Mac is stored in hex, but we need to format the return
		macstr := net.HardwareAddr(b2[:]).String()
		return macstr
	case "hexint":
		// Int is stored in hex
		if b2[0]&0x0 == 0x0 {
			// We start with 0, so strip
			return strings.TrimPrefix(hex.EncodeToString(b2), `0`)
		} else {
			// We do not start with 0, so carry on
			return hex.EncodeToString(b2)
		}
	case "hextobase10":
		// Hex value needs to be moved to base 10
		base_conversion, err := strconv.ParseInt(hex.EncodeToString(b2), 16, 64)
		check(err)
		return strconv.Itoa(int(base_conversion))
	case "str":
		// String value
		return string(b2)
	default:
		// Default is to assume hex
		return hex.EncodeToString(b2)
	}
}

func return_values(rtype string, file string, filter string) {
	var okeys []string
	var ourboard UBNTSysMap
	var ret_data []UBNT_Return_Values

	// Open EEPROM for read only
	f, err := os.Open(file)
	defer f.Close()
	check(err)

	// Start with our sysid for extra vars, pull it out of our list
	board_sysid := eeprom_read(EEPROM, f, "systemid")
	for _, board := range UBNTDeviceMap {
		if board.sysid == board_sysid {
			ourboard = board
			break
		}
	}

	// did we find our device?
	if ourboard.name == "" {
		fmt.Printf("Error: Unknown board sysid of %s! This device is not yet supported.\n", board_sysid)
		os.Exit(1)
	}

	// Load in the right list of keys to itterate over, add static keys if we got em
	if rtype == "board" {
		okeys = UBNT_Board_Vars
	} else if rtype == "system" {
		okeys = UBNT_SystemInfo_Vars
		ret_data = append(ret_data, UBNT_Return_Values{name: "cpu", value: ourboard.cpu})
		ret_data = append(ret_data, UBNT_Return_Values{name: "shortname", value: ourboard.shortname})
	} else if rtype == "tools" {
		okeys = UBNT_Tools_vars
		ret_data = append(ret_data, UBNT_Return_Values{name: "board.name", value: ourboard.name})
		ret_data = append(ret_data, UBNT_Return_Values{name: "board.shortname", value: ourboard.shortname})
	}

	// Populate our eeprom data for the rest of the data
	for _, v := range okeys {
		ret_data = append(ret_data, UBNT_Return_Values{name: v, value: eeprom_read(EEPROM, f, v)})
	}

	// Do we have a filter? if so select and return single item
	if len(filter) > 0 {
		// Does our filter item exist in our ret object?
		for _, v := range ret_data {
			if v.name == filter {
				fmt.Printf("%s\n", v.value)
				return
			}
		}
		// If we are here, our key didn't exist
		fmt.Printf("Error: Invalid key %s!\n", filter)
		os.Exit(1)
	} else {
		// Return all items because we have no filter
		for _, v := range ret_data {
			fmt.Printf("%s=%s\n", v.name, v.value)
		}
	}
}

func main() {
	// Start by defining our args
	argfile := flag.String("file", "/dev/mtd4", "The path to the EEPROM for the device")
	argboard := flag.Bool("board", false, "Print the board values")
	argsystem := flag.Bool("systeminfo", false, "Print the system info values")
	argtools := flag.Bool("tools", false, "Print similar values to ubnt-tools id")
	argfilter := flag.String("key", "", "Used to select a specific EEPROM value")
	flag.Parse()

	// Verify we can read our eeprom file
	if _, err := os.Stat(*argfile); os.IsNotExist(err) {
		fmt.Printf("Error: Unable to access %s.\n", *argfile)
		os.Exit(1)
	}

	// Is board set?
	if *argboard {
		return_values("board", *argfile, *argfilter)
	} else if *argsystem {
		return_values("system", *argfile, *argfilter)
	} else if *argtools {
		return_values("tools", *argfile, *argfilter)
	} else {
		// Tell user noting was submitted
		fmt.Fprintf(os.Stderr, "Error Invalid usage of %s:\n", os.Args[0])
		flag.PrintDefaults()
		os.Exit(1)
	}

	// We be done
	os.Exit(0)
}
