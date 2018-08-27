#!/bin/bash -e

install -v -d					    "${ROOTFS_DIR}/etc/iptables"
install -v -m 600 files/rules.v4	"${ROOTFS_DIR}/etc/iptables/rules.v4"

