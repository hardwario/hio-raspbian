#!/bin/bash -e

on_chroot << EOF
npm install -g --unsafe-perm --no-progress pm2

npm install -g --unsafe-perm --no-progres node-red
npm install -g --unsafe-perm --no-progress node-red-dashboard

pip3 install --upgrade --no-cache-dir pip
pip3 install --upgrade --no-cache-dir bcf
pip3 install --upgrade --no-cache-dir bcg

EOF
