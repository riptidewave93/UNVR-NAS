#!/bin/bash
set -e

scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Tempdir for root
GENIMAGE_ROOT=$(mktemp -d)

# "fake" file so generation is happy
touch ${GENIMAGE_ROOT}/placeholder

# Generate our boot and rootfs disk images
genimage                         \
	--rootpath "${GENIMAGE_ROOT}"     \
	--tmppath "/tmp/genimage-initial-tmppath"    \
	--inputpath "${build_path}"  \
	--outputpath "${build_path}" \
	--config "${root_path}/genimage_initial.cfg"
