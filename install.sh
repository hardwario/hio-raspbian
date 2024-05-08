#!/bin/bash
# vim: set ts=4:

step_cnt=0
step() {
    step_cnt=$(($step_cnt + 1))
	printf '\033[1;33m%s) %s\033[0m\n' $step_cnt "$@" >&2
}

export LC_ALL='C.UTF-8'
export DEBIAN_FRONTEND='noninteractive'

set -eux

step "Upgrade packages:"
sudo apt update

step "Install dependency"
sudo apt install -y curl zip wget apt-transport-https openssl

step "Install Mosquitto server and clients:"
sudo curl -sL http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key -o /etc/apt/trusted.gpg.d/mosquitto-repo.gpg.key
echo "deb [signed-by=/etc/apt/trusted.gpg.d/mosquitto-repo.gpg.key] http://repo.mosquitto.org/debian bookworm main" | sudo tee /etc/apt/sources.list.d/mosquitto.list
sudo apt update && sudo apt install -y mosquitto mosquitto-clients
sudo bash -c 'cat > /etc/mosquitto/mosquitto.conf <<EOF
pid_file /run/mosquitto/mosquitto.pid

persistence true
persistence_location /var/lib/mosquitto/

log_dest file /var/log/mosquitto/mosquitto.log

include_dir /etc/mosquitto/conf.d

listener 1883
listener 9001
protocol websockets
socket_domain ipv4
allow_anonymous true
EOF'
sudo systemctl enable mosquitto.service

step "Install Node.js version 20 (required by Node-RED)."
curl -sL  https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt install -y nodejs

step "Install PM2:"
sudo npm install -g --unsafe-perm pm2

step "Test pm2:"
pm2 list

step "Tell PM2 to run on boot:"
sudo -H PM2_HOME=/home/$(whoami)/.pm2 pm2 startup systemd -u $(whoami)
sudo -H chmod 644 /etc/systemd/system/pm2-$(whoami).service

step "PM2 log rotate"
sudo -H PM2_HOME=/home/$(whoami)/.pm2 pm2 logrotate -u $(whoami)

step "Install Node-RED:"
sudo npm install -g --unsafe-perm node-red

step "Install Node-RED plugins:"
sudo npm install -g --unsafe-perm --ignore-scripts --no-progress node-red-dashboard

step "Tell PM2 to run Node-RED:"
pm2 start `which node-red` -- --verbose
pm2 save

step "Add udev rules:"
echo 'SUBSYSTEMS=="usb", ACTION=="add", KERNEL=="ttyUSB*", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6015", ATTRS{serial}=="*-dongle*", SYMLINK+="bcUD", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/bcUD"' | sudo tee /etc/udev/rules.d/58-hardwario-usb-dongle.rules
echo 'SUBSYSTEMS=="usb", ACTION=="add", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", ENV{ID_MM_DEVICE_IGNORE}="1"' | sudo tee /etc/udev/rules.d/59-hardwario-core-module.rules
echo 'SUBSYSTEMS=="usb", ACTION=="add", KERNEL=="ttyACM*", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", SYMLINK+="bcCM", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/bcCM"' | sudo tee --append /etc/udev/rules.d/59-hardwario-core-module.rules

step "Install Python3 and pip3:"
sudo apt install -y python3 python3-pip python3-setuptools

step "Update pip (Python Package Manager) to the latest version:"
sudo rm /usr/lib/python3.*/EXTERNALLY-MANAGED
sudo pip3 install --upgrade pip

step "Install the HARDWARIO Tools:"
sudo apt install -y dfu-util
sudo pip3 install --upgrade bcf bch bcg

step "Run service for Gateway Radio Dongle:"
pm2 start /usr/bin/python3 --name "bcg-ud" -- /usr/local/bin/bcg --device /dev/bcUD
pm2 save

step "Http server"
sudo apt install -y nginx

WEB_ZIP_URL=$(curl -L -s https://api.github.com/repos/bigclownlabs/bch-hub-web/releases/latest | grep browser_download_url | grep zip | head -n 1 | cut -d '"' -f 4)
wget "$WEB_ZIP_URL" -O /tmp/web.zip
sudo unzip /tmp/web.zip -d /var/www/html
rm /tmp/web.zip

step "Install Important tools"
sudo apt install -y git mc htop tmux ncdu

step "Update .bashrc"
sed -i "s/^#alias ll='ls -l'/alias ll='ls -lha'/g" ~/.bashrc
echo 'eval "$(_BCF_COMPLETE=source bcf)"' >> ~/.bashrc
