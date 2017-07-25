#!/bin/bash -e

install -m 644 nodered.service "$ROOTFS_DIR"/etc/systemd/system/

on_chroot << EOF
npm i -g --unsafe-perm --no-progress node-red
npm i -g --unsafe-perm --no-progress node-red-contrib-blynk-websockets
npm i -g --unsafe-perm --no-progress node-red-node-twitter
npm i -g --unsafe-perm --no-progress node-red-dashboard
npm i -g --unsafe-perm --no-progress node-red-contrib-counter

systemctl enable nodered.service
systemctl start nodered.service
EOF



