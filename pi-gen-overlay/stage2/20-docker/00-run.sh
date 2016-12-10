#!/bin/bash -e
# Just add docker's apt repository, don't install it.

install -m 644 files/docker.list "$ROOTFS_DIR"/etc/apt/sources.list.d/

on_chroot apt-key add - < files/docker-2C52609D.gpg.key

on_chroot <<-EOF
	apt-get install -y apt-transport-https
	apt-get update
EOF
