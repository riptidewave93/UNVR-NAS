#!/bin/bash
set -e

# setup_mkimage is special, as it's copied to the dockerfile and ran
# same with vars.sh which we put in place
. /vars.sh

cd /usr/src
echo "Downloading genimage..."
wget ${genimage_src} -O /usr/src/${genimage_filename}

echo "Extracting genimage..."
tar -xJf /usr/src/${genimage_filename}

echo "Building genimage..."
cd ./${genimage_repopath}
./configure
make

echo "Installing genimage..."
make install

echo "Cleaning up..."
rm -rf /vars.sh # We wanna use it n burn it
rm -rf /usr/src/${genimage_repopath}*

exit 0
