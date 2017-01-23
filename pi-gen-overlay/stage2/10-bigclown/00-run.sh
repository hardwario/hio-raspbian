#!/bin/bash -e

install -m 644 files/*.list "$ROOTFS_DIR"/etc/apt/sources.list.d/

for file in files/*.gpg.key; do
	echo "Adding apt key $(basename "$file")" >&2
	on_chroot apt-key add - < "$file"
done

on_chroot <<-EOF
	apt-get install -y apt-transport-https
	apt-get update
EOF

# Enable shell and kernel messages on the serial connection.
on_chroot <<-EOF
	raspi-config nonint do_serial 0
EOF

# Change default target from Graphical Interface to Multi-User System.
on_chroot <<-EOF
	systemctl set-default multi-user.target
EOF
