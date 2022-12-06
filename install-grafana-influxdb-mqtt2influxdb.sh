#!/bin/bash
set -eu

_step_counter=0

step() {
	_step_counter=$(( _step_counter + 1 ))
	# bold cyan
	printf '\n\033[1;36m%d) %s\033[0m\n' $_step_counter "$@" >&2
}

export LC_ALL='C.UTF-8'
export DEBIAN_FRONTEND='noninteractive'

step 'Update packages'
sudo apt update

step 'Install dependencies'
sudo apt install apt-transport-https curl adduser libfontconfig python3-pip -y

step 'Add InfluxDB repository key'
curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -

step 'Add InfluxDB repository to source list'
echo "deb https://repos.influxdata.com/debian stretch stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

step 'Install InfluxDB packages'
sudo apt update && sudo apt install influxdb

if command -v pm2 >/dev/null 2>&1; then
step 'Start InfluxDB service: pm2'
sudo systemctl daemon-reload || true
sudo systemctl disable influxdb || true
sudo chown pi: -R /var/lib/influxdb
pm2 start /usr/bin/influxd --name influxdb -- -config /etc/influxdb/influxdb.conf
else
step 'Start InfluxDB service: systemd'
sudo systemctl daemon-reload
sudo systemctl enable influxdb
sudo systemctl start influxdb
fi

step 'Install mqtt2influxdb packages'
sudo -H pip3 install -U --no-cache-dir mqtt2influxdb

step 'Download default config for HARDWARIO Kit'
sudo mkdir -p /etc/hardwario
sudo wget "https://raw.githubusercontent.com/hardwario/bch-mqtt2influxdb/master/config-bigclown.yml" -O "/etc/hardwario/mqtt2influxdb.yml"

step 'Configuration file test'
mqtt2influxdb -c /etc/hardwario/mqtt2influxdb.yml --test

step 'Start the MQTT to InfluxDB service: pm2'
pm2 start `which python3` --name "mqtt2influxdb" -- `which mqtt2influxdb` -c /etc/hardwario/mqtt2influxdb.yml

step 'Download Grafana deb'
wget $(wget "https://api.github.com/repos/fg2it/grafana-on-raspberry/releases/latest" -q -O - | grep browser_download_url | grep armhf.deb | head -n 1 | cut -d '"' -f 4) -O /tmp/grafana.deb

step 'Install Grafana'
sudo dpkg -i /tmp/grafana.deb
sudo chown pi: -R /etc/grafana /usr/share/grafana /var/log/grafana /var/lib/grafana

step 'Remove deb Grafana'
rm /tmp/grafana.deb

step 'Start Grafana service'

if command -v pm2 >/dev/null 2>&1; then
sudo systemctl daemon-reload || true
sudo systemctl disable grafana-server || true
sudo systemctl stop grafana-server || true
pm2 start /usr/sbin/grafana-server --name grafana -- \
 -config=/etc/grafana/grafana.ini \
 -homepath /usr/share/grafana \
 cfg:default.paths.logs=/var/log/grafana \
 cfg:default.paths.data=/var/lib/grafana \
 cfg:default.paths.plugins=/var/lib/grafana/plugins \
 cfg:default.paths.provisioning=/etc/grafana/provisioning
else
step 'Start InfluxDB service: systemd'
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
fi

step 'Save the PM2 state (so it will start after reboot)'
pm2 save

IP=$(ifconfig | grep 'inet '| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $2}')
echo "Grafana run on http://$IP:3000"
echo "Username: admin"
echo "Password: admin"
