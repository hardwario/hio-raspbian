#!/bin/bash
# vim: set ts=4:
# set -eu

IMAGE="2018-11-13-raspbian-stretch-lite.img"
BUILD_DIR="$(pwd)/build"
ROOT_DIR=$BUILD_DIR/raspbian

die() {
	printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2
	shift
	printf '  %s\n' "$@"
	exit 2
}

einfo() {
	printf '\033[1;34m%s\033[0m\n' "$@" >&2
}

step_test() {
	if [ ! -f install.sh ]; then
		die "Missing install.sh"
	fi

	if [ "$EUID" -ne 0 ]; then
		die "Please run as root"
	fi
}

step_download () {
	wget "https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2018-11-15/2018-11-13-raspbian-stretch-lite.zip" -O "${IMAGE}.zip"
	unzip "${IMAGE}.zip"
}

step_unzip() {
	einfo "Uzip ${IMAGE}.zip"
	unzip "${IMAGE}.zip"
}

step_prepare_chroot() {
	einfo "Prepere"
	kpartx -v -a "${IMAGE}"

	LOOP_BOOT=/dev/mapper/$(kpartx -l "${IMAGE}" | head -n 1 | awk '{print $1}')
	LOOP_ROOT=/dev/mapper/$(kpartx -l "${IMAGE}" | tail -n 1 | awk '{print $1}')

	mkdir -p "${ROOT_DIR}"

	sleep 3

	mount -o rw "${LOOP_ROOT}" "${ROOT_DIR}"
	mount -o rw "${LOOP_BOOT}" "${ROOT_DIR}/boot"

	mount --bind /dev "${ROOT_DIR}/dev/"
	mount --bind /dev/pts "${ROOT_DIR}/dev/pts"
	mount --bind /sys "${ROOT_DIR}/sys/"
	mount --bind /proc "${ROOT_DIR}/proc/"
	mount --bind /etc/resolv.conf "${ROOT_DIR}/etc/resolv.conf"

	cp /usr/bin/qemu-arm-static ${ROOT_DIR}/usr/bin/
	sed -i 's/^/#CHROOT /g' "${ROOT_DIR}/etc/ld.so.preload"
}

step_enable_ssh() {
	touch "${ROOT_DIR}/boot/ssh"
}

step_chroot() {
	einfo "Chroot"

	cat install.sh | HOME=/home/pi chroot --userspec=1000:1000 ${ROOT_DIR} /bin/bash

	cp -r www/* "${ROOT_DIR}/var/www/html/"

	HOME=/home/pi chroot --userspec=1000:1000 ${ROOT_DIR} /bin/bash

	echo "pm2 kill" | HOME=/home/pi chroot --userspec=1000:1000 ${ROOT_DIR} /bin/bash
}

step_clean_up_chroot() {
	einfo "Clean up"

	rm -f "${ROOT_DIR}/usr/bin/qemu-arm-static"

	sed -i 's/^#CHROOT //g' "${ROOT_DIR}/etc/ld.so.preload"

	sync

	umount ${ROOT_DIR}/{dev/pts,dev,sys,proc,boot,etc/resolv.conf,}

	sync

	kpartx -d -v "${IMAGE}"
}

step_test
step_download
step_unzip
step_enable_ssh
step_prepare_chroot
step_chroot
step_clean_up_chroot
