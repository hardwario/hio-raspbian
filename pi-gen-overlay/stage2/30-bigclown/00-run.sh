#!/bin/bash -e

install -m 644 files/bigclown.list "$ROOTFS_DIR"/etc/apt/sources.list.d/

on_chroot apt-key add - < files/bigclown.gpg.key

on_chroot <<-EOF
	apt-get install -y apt-transport-https
	apt-get update
EOF
