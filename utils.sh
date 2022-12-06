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

_step_counter=0

step() {
	_step_counter=$(( _step_counter + 1 ))
	printf '\n\033[1;36m%d) %s\033[0m\n' $_step_counter "$@" >&2  # bold cyan
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
	dd if=/dev/zero bs=1M count=$(($2 + 1)) >> "$1"

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

	sleep 5m

	kpartx -d -v "${IMAGE}"

	sleep 5m

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

	echo "Disable IPv6 in APT"
	echo 'Acquire::ForceIPv4 "true";' >> "$ROOT_DIR/etc/apt/apt.conf.d/99force-ipv4"
	echo "Modify source.list"
}

chroot_disable() {
	echo "Enable IPv6 in APT"
	rm "$ROOT_DIR/etc/apt/apt.conf.d/99force-ipv4"
	echo "Remove modify source.list"
	sed -r -i'' "s/reflection.oss.ou.edu\/raspbian\/raspbian/raspbian.raspberrypi.org\/raspbian/g" "$ROOT_DIR/etc/apt/sources.list"

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
	systemd-nspawn -D "${ROOT_DIR}" -E HOME=/home/pi -E LC_ALL='C.UTF-8' --pipe -u 1000 bin/bash
}

chroot_cmd() {
	echo "$@" | chroot_bash
}

img_shrink() {
	beforesize=$(ls -lh "$1" | cut -d ' ' -f 5)
	parted_output=$(parted -ms "$1" unit B print | tail -n 1)
	partnum=$(echo "$parted_output" | cut -d ':' -f 1)
	partstart=$(echo "$parted_output" | cut -d ':' -f 2 | tr -d 'B')
	loopback=$(losetup -f --show -o $partstart "$1")
	tune2fs_output=$(tune2fs -l "$loopback")
	currentsize=$(echo "$tune2fs_output" | grep '^Block count:' | tr -d ' ' | cut -d ':' -f 2)
	blocksize=$(echo "$tune2fs_output" | grep '^Block size:' | tr -d ' ' | cut -d ':' -f 2)

	#Make sure filesystem is ok
	e2fsck -p -f "$loopback"
	minsize=$(resize2fs -P "$loopback" | cut -d ':' -f 2 | tr -d ' ')
	if [[ $currentsize -eq $minsize ]]; then
	echo "Image already shrunk to smallest size"
	echo "currentsize: $currentsize minsize: $minsize"
	losetup -d "$loopback"
	return 0
	fi

	#Add some free space to the end of the filesystem
	extra_space=$(($currentsize - $minsize))
	for space in 5000 1000 100; do
	if [[ $extra_space -gt $space ]]; then
		minsize=$(($minsize + $space))
		break
	fi
	done

	#Shrink filesystem
	resize2fs -p "$loopback" $minsize
	if [[ $? != 0 ]]; then
	losetup -d "$loopback"
	die "ERROR: resize2fs failed..."
	fi

	losetup -d "$loopback"
	sleep 5m

	#Shrink partition
	partnewsize=$(($minsize * $blocksize))
	newpartend=$(($partstart + $partnewsize))
	parted -s -a minimal "$1" rm $partnum >/dev/null
	parted -s "$1" unit B mkpart primary $partstart $newpartend >/dev/null

	#Truncate the file
	endresult=$(parted -ms "$1" unit B print free | tail -1 | cut -d ':' -f 2 | tr -d 'B')
	truncate -s $endresult "$1"
	aftersize=$(ls -lh "$1" | cut -d ' ' -f 5)

	echo "Shrunk $1 from $beforesize to $aftersize"
}
