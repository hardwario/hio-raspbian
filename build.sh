#!/bin/bash
# vim: set ts=4:
set -eu

URL="https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-09-30/2019-09-26-raspbian-buster-lite.zip"
SHA256="a50237c2f718bd8d806b96df5b9d2174ce8b789eda1f03434ed2213bbca6c6ff"
IMAGE="2019-09-26-raspbian-buster-lite.img"

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

chroot_bash() {
	# HOME=/home/pi LC_ALL='C.UTF-8' chroot --userspec=1000:1000 ${ROOT_DIR} /bin/bash
	HOME=/home/pi LC_ALL='C.UTF-8' setarch linux32 chroot --userspec=1000:1000 ${ROOT_DIR} /bin/bash
}

chroot_cmd() {
	echo "$@" | chroot_bash
}

step_test() {
	if [ ! -f install.sh ]; then
		die "Missing install.sh"
	fi

	# if [ `getconf LONG_BIT` = "64" ]; then
	# 	if [ ! -f /lib/modules/$(uname -r)/kernel/fs/binfmt_misc.ko ]; then
	# 		die "Missing binfmt_misc.ko"
	# 	fi
	# fi

	if [ ! -f /usr/bin/qemu-arm-static ]; then
		die "Missing /usr/bin/qemu-arm-static"
	fi

	if [ "$EUID" -ne 0 ]; then
		die "Please run as root"
	fi
}

step_download () {
	einfo "Download"
	wget -q "https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-09-30/2019-09-26-raspbian-buster-lite.zip" -O "${IMAGE}.zip"

	if ! echo "${SHA256} ${IMAGE}.zip" | sha256sum --check --status; then
		die "Bad sha256"
	fi
}

step_unzip() {
	einfo "Uzip ${IMAGE}.zip"
	unzip -o "${IMAGE}.zip"
	# rm "${IMAGE}.zip"
}

step_chroot_enable() {
	einfo "Chroot enable"

	if [ -d "${ROOT_DIR}" ]; then
		return 0
	fi

	# if [ `getconf LONG_BIT` = "64" ]; then
	# modprobe binfmt_misc || true
	# fi

	kpartx -v -a "${IMAGE}"

	LOOP_BOOT=/dev/mapper/$(kpartx -l "${IMAGE}" | head -n 1 | awk '{print $1}')
	LOOP_ROOT=/dev/mapper/$(kpartx -l "${IMAGE}" | tail -n 1 | awk '{print $1}')

	mkdir -p "${ROOT_DIR}"

	sleep 3

	mount -o rw "${LOOP_ROOT}" "${ROOT_DIR}"
	mount -o rw "${LOOP_BOOT}" "${ROOT_DIR}/boot"

	mount --bind /dev "${ROOT_DIR}/dev/"
	mount --bind /dev/pts "${ROOT_DIR}/dev/pts"
	mount --bind  /sys "${ROOT_DIR}/sys/"
	mount -t proc proc "${ROOT_DIR}/proc/"
	mount --bind /etc/resolv.conf "${ROOT_DIR}/etc/resolv.conf"

	dpkg-reconfigure qemu-user-static

	cp /usr/bin/qemu-arm-static ${ROOT_DIR}/usr/bin/

	cp  ${ROOT_DIR}/bin/true ${ROOT_DIR}/usr/bin/ischroot

	sed -i 's/^\//#CHROOT \//g' "${ROOT_DIR}/etc/ld.so.preload"
}

step_enable_ssh() {
	einfo "Enable ssh"
	touch "${ROOT_DIR}/boot/ssh"
}

step_change_hostname() {
	einfo "Change hostname"
	echo "hub" | tee "${ROOT_DIR}/etc/hostname"
	sed -i "s/raspberrypi/hub/" "${ROOT_DIR}/etc/hosts"
}

step_copy_files() {
	einfo "Copy files"
	install -m 755 -o 0 -g 0  files/update-motd.d/* "${ROOT_DIR}/etc/update-motd.d/"
	cp -r files/node-red "${ROOT_DIR}/home/pi/.node-red"
	chown 1000:1000 -R "${ROOT_DIR}/home/pi/.node-red"

	install -m 666 files/wpa_supplicant.example.conf "${ROOT_DIR}/boot/wpa_supplicant.example.conf"
}

step_install_sh() {
	einfo "Run install.sh"

	cat install.sh | chroot_bash

	chroot_cmd "pm2 kill"
}

step_finish() {
	einfo "Clean up"
	chroot_cmd "sudo apt clean && sudo apt autoremove"
}

step_chroot_disable() {
	einfo "Chroot disable"

	rm -f "${ROOT_DIR}/usr/bin/qemu-arm-static"

	rm -f "${ROOT_DIR}/usr/bin/ischroot"

	sed -i 's/^#CHROOT //g' "${ROOT_DIR}/etc/ld.so.preload"

	sync

	sleep 1

	umount ${ROOT_DIR}/{dev/pts,dev,sys,proc,boot,etc/resolv.conf,}

	sync

	kpartx -d -v "${IMAGE}"

	sleep 1

	rmdir "${ROOT_DIR}"
}

step_zip() {
	einfo "Zip"
	mv ${IMAGE} bc-raspbian-${TRAVIS_TAG:-vdev}.img
	zip bc-raspbian-${TRAVIS_TAG:-vdev}.zip bc-raspbian-${TRAVIS_TAG:-vdev}.img
}

step_test
step_download
step_unzip
step_chroot_enable
step_enable_ssh
step_change_hostname
step_copy_files
step_install_sh
step_finish
step_chroot_disable
step_zip
