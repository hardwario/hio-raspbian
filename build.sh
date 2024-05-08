#!/bin/bash
# vim: set ts=4:
set -eu

. ./utils.sh


if [[ ! -v URL ]]; then
URL="https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2024-03-15/2024-03-15-raspios-bookworm-armhf-lite.img.xz"
SHA256="4fa99737265ac338a9ed0643f502246b97b928e5dfffa92939242e26e290638d"
NAME="hio-raspbian-bookworm-lite"
fi

IMAGE=${URL##*/}
IMAGE="$(pwd)/${IMAGE%.*}"

check_is_run_as_root

check_commands parted losetup tune2fs sha256sum e2fsck resize2fs kpartx systemd-nspawn

if [ ! -f install.sh ]; then
	die "Missing install.sh"
fi

if [ `getconf LONG_BIT` = "64" ]; then
	if [ ! -f /lib/modules/$(uname -r)/kernel/fs/binfmt_misc.ko ]; then
		die "Missing binfmt_misc.ko"
	fi
fi

if [ ! -f /usr/bin/qemu-arm-static ]; then
	die "Missing /usr/bin/qemu-arm-static"
fi

IMAGE_XZ="${IMAGE}.xz"

step "Download"
echo "$URL as $IMAGE_XZ"
wget -q "$URL" -O "$IMAGE_XZ"
check_sha256_sum "$IMAGE_XZ" $SHA256

step "Uzip"
unxz "$IMAGE_XZ"

step "Resize image"
img_resize "$IMAGE" 512


step "Mount img"
img_mount "$IMAGE"


step "Enable ssh server"
touch "$ROOT_DIR/boot/ssh"


step "Change hostname"
echo "hub" | tee "$ROOT_DIR/etc/hostname"
sed -i "s/raspberrypi/hub/" "$ROOT_DIR/etc/hosts"


step "Copy files"
install -m 755 -o 0 -g 0  files/update-motd.d/* "$ROOT_DIR/etc/update-motd.d/"
cp -r files/node-red "$ROOT_DIR/home/pi/.node-red"
chown 1000:1000 -R "$ROOT_DIR/home/pi/.node-red"
install -m 666 files/wpa_supplicant.example.conf "$ROOT_DIR/boot/wpa_supplicant.example.conf"
echo "${VERSION:-vdev}" > "$ROOT_DIR/usr/lib/hub-version"


step "Chroot enable"
chroot_enable


step "Run install.sh"
cat install.sh | chroot_bash


step "Clean up"
chroot_cmd "pm2 kill"
chroot_cmd 'sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" clean -y'
chroot_cmd 'sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" autoremove -y'
chroot_cmd "df -h"


step "Chroot disable"
chroot_disable


step "Umount img"
img_umount "$IMAGE"


step "Shrink img"
img_shrink "$IMAGE"


step "Zip $NAME-${VERSION:-vdev}"
mv "$IMAGE" "$NAME-${VERSION:-vdev}.img"
zip "$NAME-${VERSION:-vdev}.zip" "$NAME-${VERSION:-vdev}.img"


einfo "--- Grafana, InfluxDB, mqtt2influxdb ---"

step "Rename img"
mv "$NAME-${VERSION:-vdev}.img" "$IMAGE"


step "Resize image"
img_resize "$IMAGE" 640


step "Mount img"
img_mount "$IMAGE"


step "Chroot enable"
chroot_enable


step "Run install-grafana-influxdb-mqtt2influxdb.sh"
echo "pm2 resurrect" | cat - install-grafana-influxdb-mqtt2influxdb.sh | chroot_bash


step "Clean up"
chroot_cmd "pm2 kill"
chroot_cmd 'sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" clean -y'
chroot_cmd 'sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" autoremove -y'
chroot_cmd "df -h"


step "Chroot disable"
chroot_disable


step "Umount img"
img_umount "$IMAGE"


step "Shrink img"
img_shrink "$IMAGE"


step "Zip $NAME-grafana-influxdb-${VERSION:-vdev}"
mv $IMAGE "$NAME-grafana-influxdb-${VERSION:-vdev}.img"
zip "$NAME-grafana-influxdb-${VERSION:-vdev}.zip" "$NAME-grafana-influxdb-${VERSION:-vdev}.img"
