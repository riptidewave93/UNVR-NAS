#!/usr/bin/python3
import argparse
import binascii
import mmap
import sys
import zlib

from io import BytesIO

from pathlib import Path

def main(fwfile: str, savedir: str):
    # Does the file exist?
    if not Path(fwfile).is_file():
        print(f"Error: {fwfile} is not a file! Exiting...")
        sys.exit(1)

    # Does our save dir exist?
    if not Path(savedir).is_dir():
        print(f"Warning: {savedir} is not a directory, attempting to create it...")
        Path(savedir).mkdir(parents=True)

    # Start parsing the OTA file
    with open(fwfile, 'rb+') as f:
        # Read from disk, not memory
        mm = mmap.mmap(f.fileno(), 0)

        ubntheader = mm.read(0x104) # Read header in
        ubntheadercrc = int.from_bytes(mm.read(0x4)) # Read header CRC, convert to int

        # Do we have the UBNT header?
        if ubntheader[0:4].decode("utf-8") != "UBNT":
            print(f"Error: {fwfile} is missing the UBNT header! Is this the right firmware file?")
            sys.exit(1)

        # Is the header CRC valid?
        if zlib.crc32(ubntheader) != ubntheadercrc:
            print(f"Error: {fwfile} has in incorrect CRC for it's header! Please re-download the file!")
            sys.exit(1)

        # If we are here, that's a great sign :) 
        ubnt_fw_ver_string = ubntheader[4:].decode("utf-8")
        print(f"Loaded in firmware file {ubnt_fw_ver_string}")

        # Start parsing out all of the files in the OTA
        #files = []
        fcount = 1
        while True:
            file_header_offset = mm.find(b'\x46\x49\x4C\x45') # FILE in hex bye string
            # Are we done scanning the file?
            if file_header_offset == -1:
                break

            # We found one, seek to it
            mm.seek(file_header_offset)
            file_header = mm.read(0x38) # Entire header
            file_position = file_header[39] # Increments with files read, can be used to validate this is a file for us
            file_location = file_header_offset+0x38 # header location - header = data :)

            # Is this a VALID file?!
            if fcount == file_position:
                file_name = file_header[4:33].decode("utf-8").rstrip('\x00') # Name/type of FILE
                file_length = int(file_header[48:52].hex(), 16)
                print(f"{file_name} is at offset {"0x%0.2X" % file_location}, {file_length} bytes")
                # print(int(file_header[52:56].hex(), 16)) # Maybe reserved memory or partition size? We don't use this tho
                #files.extend([(file_position, file_name, file_location, file_length)])
                fcount = fcount+1 # Increment on find!

                fcontents = mm.read(file_length) # Read into memory
                file_footer_crc32 = mm.read(0x8)[0:4] # Read in tailing 8 bytes (crc32) footer, but we only want the first 4

                # Does our calculated crc32 match the unifi footer in the img?
                if hex(zlib.crc32(file_header + fcontents)).lstrip('0x') != file_footer_crc32.hex().lstrip('0'):
                    print(f"Error: Contents of {file_name} does not match the Unifi CRC! Please re-download the file!")
                    sys.exit(1)                    

                # Write file out since our mmap position is now AT the data, and we parsed the length
                with open(f"{savedir}/{file_name}.bin", "wb") as wf:
                    wf.write(fcontents) # Write out file
                print(f"{file_name} has been written to {savedir}/{file_name}.bin")

                del fcontents # Cleanup memory for next run

        print(f"Finished extracting the contents of {fwfile}, enjoy!")


if __name__ == "__main__":
    parser = argparse.ArgumentParser("ubnt-fw-parse for Dream Machines")
    parser.add_argument("file", help="The Ubiquiti firmware file to parse", type=str)
    parser.add_argument("savedir", help="The directory to save the parsed files to", type=str)
    args = parser.parse_args()
    main(args.file, args.savedir)
