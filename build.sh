#!/bin/bash
# vim: set ts=4:
set -eu

. ./utils.sh

if [[ ! -v URL ]]; then
URL="http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-14/2020-02-13-raspbian-buster-lite.zip"
SHA256="12ae6e17bf95b6ba83beca61e7394e7411b45eba7e6a520f434b0748ea7370e8"
NAME="hio-raspbian-buster-lite"
fi

IMAGE=${URL##*/}
IMAGE="$(pwd)/${IMAGE%.*}.img"

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

IMAGE_ZIP="${IMAGE}.zip"

step "Download"
echo "$URL as $IMAGE_ZIP"
wget -q "$URL" -O "$IMAGE_ZIP"
check_sha256_sum "$IMAGE_ZIP" $SHA256


step "Uzip"
unzip -o "$IMAGE_ZIP"
rm "$IMAGE_ZIP"


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
echo "${TRAVIS_TAG:-vdev}" > "$ROOT_DIR/usr/lib/hub-version"


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


step "Zip $NAME-${TRAVIS_TAG:-vdev}"
mv "$IMAGE" "$NAME-${TRAVIS_TAG:-vdev}.img"
zip "$NAME-${TRAVIS_TAG:-vdev}.zip" "$NAME-${TRAVIS_TAG:-vdev}.img"


einfo "--- Grafana, InfluxDB, mqtt2influxdb ---"

step "Rename img"
mv "$NAME-${TRAVIS_TAG:-vdev}.img" "$IMAGE"


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


step "Zip $NAME-grafana-influxdb-${TRAVIS_TAG:-vdev}"
mv $IMAGE "$NAME-grafana-influxdb-${TRAVIS_TAG:-vdev}.img"
zip "$NAME-grafana-influxdb-${TRAVIS_TAG:-vdev}.zip" "$NAME-grafana-influxdb-${TRAVIS_TAG:-vdev}.img"
