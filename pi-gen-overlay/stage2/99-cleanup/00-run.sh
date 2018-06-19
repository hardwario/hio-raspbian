#!/bin/bash -e

on_chroot <<-EOF
	apt-get clean
	rm -rf /home/travis
EOF
