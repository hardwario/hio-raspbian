#!/bin/bash -e

install -m 644 files/*.list "$ROOTFS_DIR"/etc/apt/sources.list.d/

for file in files/*.gpg.key; do
	echo "Adding apt key $(basename "$file")" >&2
	on_chroot apt-key add - < "$file"
done

install -m 444 files/libssl1.0.0_1.0.1t-1+deb8u7_armhf.deb "$ROOTFS_DIR/tmp"
install -m 444 files/libwebsockets3_1.2.2-1_armhf.deb "$ROOTFS_DIR/tmp"

on_chroot <<-EOF
	apt-get install -y apt-transport-https
	apt-get update

	sudo dpkg -i /tmp/libssl1.0.0_1.0.1t-1+deb8u7_armhf.deb
	sudo dpkg -i /tmp/libwebsockets3_1.2.2-1_armhf.deb
EOF

# Enable shell and kernel messages on the serial connection.
on_chroot <<-EOF
	raspi-config nonint do_serial 0
EOF

# Change default target from Graphical Interface to Multi-User System.
on_chroot <<-EOF
	systemctl set-default multi-user.target
EOF
