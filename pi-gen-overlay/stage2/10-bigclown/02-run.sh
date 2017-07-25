#!/bin/bash -e

install -m 644 files/nodered.service "$ROOTFS_DIR"/etc/systemd/system/

cp -r files/install "$ROOTFS_DIR"/home/pi
chown -R 1000:1000 "$ROOTFS_DIR"/home/pi/install

on_chroot << EOF
npm i -g --unsafe-perm --no-progress node-red
npm i -g --unsafe-perm --no-progress node-red-contrib-blynk-websockets
npm i -g --unsafe-perm --no-progress node-red-node-twitter
npm i -g --unsafe-perm --no-progress node-red-dashboard
npm i -g --unsafe-perm --no-progress node-red-contrib-counter

systemctl enable nodered.service
EOF
