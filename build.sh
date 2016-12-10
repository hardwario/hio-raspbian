#!/bin/sh
set -eu

export IMG_NAME='bc-hub'
export DEBIAN_FRONTEND='noninteractive'
export LC_ALL='C.UTF-8'

if [ -n "${TRAVIS_TAG:-}" ]; then
	export IMG_DATE="$TRAVIS_TAG"
fi

cd "$(dirname "$0")"

mkdir -p build
cd build

# Assembly our customized pi-gen.
cp -rf ../pi-gen/* ../pi-gen-overlay/* .
rm -rf stage2/EXPORT_NOOBS stage3 stage4

for file in ../pi-gen-overlay/*.patch; do
	echo "Applying patch ${file%/*}"
	patch -p1 < "$file"
done

# Build customized stage2 image.
./build.sh
