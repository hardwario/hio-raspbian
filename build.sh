#!/bin/sh
set -eu

export IMG_NAME='bc-hub'
export DEBIAN_FRONTEND='noninteractive'
export LC_ALL='C.UTF-8'

cd "$(dirname "$0")"

mkdir -p build
cd build

# Assembly our customized pi-gen.
cp -rf ../pi-gen/* ../pi-gen-overlay/* .
rm -rf stage2/EXPORT_NOOBS stage3 stage4

# Build customized stage2 image.
./build.sh
