#!/bin/bash -e

# Apply timezone changes.
on_chroot <<-EOF
	dpkg-reconfigure -f noninteractive tzdata
EOF
