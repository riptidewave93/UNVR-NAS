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

// Type for EEPROM structure
type EEPROM_Value struct {
	name, description, vtype string
	offset, length           int64
}

// Build our BOARD eeprom structure
var BOARD = []EEPROM_Value{
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
}

// Build our SYSTEM_INFO eeprom structure
var SYSTEM_INFO = []EEPROM_Value{
	// Missing values:
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
		length:      0x5,
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
}

// Build our vars that are similar to running ubnt-tools id
var UBNT_TOOLS = []EEPROM_Value{
	{
		name:        "board.sysid",
		description: "Device Model/Revision Identifier",
		offset:      0xC,
		length:      0x2,
		vtype:       "hex",
	},
	{
		name:        "board.serialno",
		description: "Serial Number",
		offset:      0x0,
		length:      0x5,
		vtype:       "hex",
	},
	{
		name:        "board.bom",
		description: "Board Bill of Materials Revision Code",
		offset:      0xD024,
		length:      0xC,
		vtype:       "str",
	},
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

func return_values(values []EEPROM_Value, file string, filter string) {
	// Open EEPROM for read only
	f, err := os.Open(file)
	defer f.Close()
	check(err)

	// If select is set, select our item, else return all
	if len(filter) > 0 {
		// Read value
		fmt.Printf("%s\n", eeprom_read(values, f, filter))
	} else {
		// read all
		for _, v := range values {
			fmt.Printf("%s=%s\n", v.name, eeprom_read(values, f, v.name))
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
		return_values(BOARD, *argfile, *argfilter)
	} else if *argsystem {
		return_values(SYSTEM_INFO, *argfile, *argfilter)
	} else if *argtools {
		return_values(UBNT_TOOLS, *argfile, *argfilter)
	} else {
		// Tell user noting was submitted
		fmt.Fprintf(os.Stderr, "Error Invalid usage of %s:\n", os.Args[0])
		flag.PrintDefaults()
		os.Exit(1)
	}

	// We be done
	os.Exit(0)
}
