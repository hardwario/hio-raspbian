#!/bin/bash
set -eu

_step_counter=0

step() {
	_step_counter=$(( _step_counter + 1 ))
	printf '\n\033[1;36m%d) %s\033[0m\n' $_step_counter "$@" >&2  # bold cyan
}

step 'Update and upgrade packages'
sudo apt update && sudo apt upgrade -y

step 'Install dependencies'
sudo apt install apt-transport-https curl adduser libfontconfig python3-pip -y

step 'Add InfluxDB repository key'
curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -

step 'Add InfluxDB repository to source list'
echo "deb https://repos.influxdata.com/debian stretch stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

step 'Install InfluxDB packages'
sudo apt update && sudo apt install influxdb

step 'Enable InfluxDB service'
sudo systemctl daemon-reload
sudo systemctl enable influxdb

step 'Start InfluxDB service'
sudo systemctl start influxdb

step 'Install mqtt2influxdb packages'
sudo -H pip3 install -U --no-cache-dir mqtt2influxdb

step 'Download default config for bigclown'
sudo mkdir -p /etc/bigclown
sudo wget "https://raw.githubusercontent.com/bigclownlabs/bch-mqtt2influxdb/master/config-bigclown.yml" -O "/etc/bigclown/mqtt2influxdb.yml"

step 'Configuration file test'
mqtt2influxdb -c /etc/bigclown/mqtt2influxdb.yml --test

step 'Start the MQTT to InfluxDB service'
pm2 start `which python3` --name "mqtt2influxdb" -- `which mqtt2influxdb` -c /etc/bigclown/mqtt2influxdb.yml

step 'Save the PM2 state (so it will start after reboot)'
pm2 save

step 'Download Grafana deb'
wget $(wget "https://api.github.com/repos/fg2it/grafana-on-raspberry/releases/latest" -q -O - | grep browser_download_url | grep armhf.deb | head -n 1 | cut -d '"' -f 4) -O /tmp/grafana.deb

step 'Install Grafana'
sudo dpkg -i /tmp/grafana.deb

step 'Remove deb Grafana'
rm /tmp/grafana.deb

step 'Eneble Grafana service'
sudo systemctl daemon-reload
sudo systemctl enable grafana-server

step 'Start Grafana service'
sudo systemctl start grafana-server

IP=$(ifconfig | grep 'inet '| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $2}')
echo "Grafana run on http://$IP:3000"
echo "Username: admin"
echo "Password: admin"
