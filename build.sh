#!/bin/sh
set -eu

export IMG_NAME='bc-hub'
export DEBIAN_FRONTEND='noninteractive'
export LC_ALL='C.UTF-8'

cd "$(dirname "$0")"

mkdir -p build
cp -rf pi-gen/* pi-gen-overlay/* build/

cd build
./build.sh
