#!/bin/bash -e

install -m 644 files/nodesource.list "$ROOTFS_DIR"/etc/apt/sources.list.d/

on_chroot apt-key add - < files/nodesource.gpg.key

on_chroot <<-EOF
	apt-get install -y apt-transport-https
	apt-get update
	apt-get install nodejs
EOF
