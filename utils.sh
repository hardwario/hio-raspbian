# vim: set ts=4:

ROOT_DIR="$(pwd)/build/raspbian"

die() {
	# bold red
	printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2
	shift
	printf '  %s\n' "$@"
	exit 2
}

einfo() {
	# bold cyan
	printf '\033[1;36m> %s\033[0m\n' "$@" >&2
}

ewarn() {
	# bold yellow
	printf '\033[1;33m> %s\033[0m\n' "$@" >&2
}

has() {
	command -v "$1" >/dev/null 2>&1
}

check_is_run_as_root() {
	if [ "$EUID" -ne 0 ]; then
		die "Please run as root"
	fi
}

check_commands() {
	for command in $@; do
		has "$command" && continue
		die "$command is not installed."
	done
}

check_sha256_sum() {
	# usage: check_sha256_sum file_path sha256
	if ! echo "$2 $1" | sha256sum --check --status; then
		die "Bad sha256"
	fi
}

img_resize() {
	# usage: img_resize img_path size_in_MB
	dd if=/dev/zero bs=1M count=$2 >> "$1"

	parted_output=$(parted -ms "$1" unit MB print | tail -n 1)
	partstart=$(echo "$parted_output" | cut -d ':' -f 2 | tr -d 'MB')
	partend=$(echo "$parted_output" | cut -d ':' -f 3 | tr -d 'MB')
	# echo "$partstart $partend"

	loopback=$(losetup -f -P --show "$1")
	# parted $loopback unit MB print
	parted $loopback rm 2
	parted $loopback unit MB mkpart primary $partstart $(($partend + $2))

	e2fsck -y -f "$loopback"p2
	resize2fs "$loopback"p2

	# parted $loopback unit MB print

	losetup -d "$loopback"
}

img_mount() {
	# usage: mount_img img_path

	kpart_output=$(kpartx -v -a -s "$1")

	loop_boot=/dev/mapper/$(echo "$kpart_output" | awk 'NR==1{print $3}')
	loop_root=/dev/mapper/$(echo "$kpart_output" | awk 'NR==2{print $3}')

	echo "loop_boot ${loop_boot}"
	echo "loop_root ${loop_root}"

	mkdir -p "$ROOT_DIR"

	mount -o rw "${loop_root}" "${ROOT_DIR}"
	mount -o rw "${loop_boot}" "${ROOT_DIR}/boot"
}

img_umount() {
	umount -l "${ROOT_DIR}/boot"
	umount -l "${ROOT_DIR}"

	sleep 1

	kpartx -d -v "${IMAGE}"

	rmdir "${ROOT_DIR}"
}

chroot_enable() {
	# # uncoment for use command chroot
	# mount --bind /dev "${ROOT_DIR}/dev/"
	# mount --bind /dev/pts "${ROOT_DIR}/dev/pts"
	# mount --bind  /sys "${ROOT_DIR}/sys/"
	# mount -t proc proc "${ROOT_DIR}/proc/"
	# mount --bind /etc/resolv.conf "${ROOT_DIR}/etc/resolv.conf"

	cp /usr/bin/qemu-arm-static "${ROOT_DIR}/usr/bin"

	cp  ${ROOT_DIR}/bin/true ${ROOT_DIR}/usr/bin/ischroot

	sed -i 's/^\//#CHROOT \//g' "${ROOT_DIR}/etc/ld.so.preload"
}

chroot_disable() {
	rm -f "${ROOT_DIR}/usr/bin/qemu-arm-static"

	rm -f "${ROOT_DIR}/usr/bin/ischroot"

	sed -i 's/^#CHROOT //g' "${ROOT_DIR}/etc/ld.so.preload"

	# # uncoment for use command chroot
	# umount "${ROOT_DIR}/etc/resolv.conf"
	# umount "${ROOT_DIR}/proc"
	# umount "${ROOT_DIR}/sys"
	# umount "${ROOT_DIR}/dev/pts"
	# umount "${ROOT_DIR}/dev"
}

chroot_bash() {
	# HOME=/home/pi LC_ALL='C.UTF-8' chroot --userspec=1000:1000 ${ROOT_DIR} /bin/bash
	# HOME=/home/pi LC_ALL='C.UTF-8' setarch linux32 chroot --userspec=1000:1000 ${ROOT_DIR} /bin/bash
	systemd-nspawn -D "${ROOT_DIR}" -E HOME=/home/pi -E LC_ALL='C.UTF-8' -u 1000 bin/bash
}

chroot_cmd() {
	echo "$@" | chroot_bash
}

add_fix_apt_for_travis_ci() {
	echo "Disable IPv6 in APT"
	echo 'Acquire::ForceIPv4 "true";' >> "$ROOT_DIR/etc/apt/apt.conf.d/99force-ipv4"
	echo "Modify source.list"
	sed -r -i'' "s/raspbian.raspberrypi.org\/raspbian/reflection.oss.ou.edu\/raspbian\/raspbian/g" "$ROOT_DIR/etc/apt/sources.list"
}

remove_fix_apt_for_travis_ci() {
	echo "Enable IPv6 in APT"
	rm "$ROOT_DIR/etc/apt/apt.conf.d/99force-ipv4"
	echo "Remove modify source.list"
	sed -r -i'' "s/reflection.oss.ou.edu\/raspbian\/raspbian/raspbian.raspberrypi.org\/raspbian/g" "$ROOT_DIR/etc/apt/sources.list"
}
