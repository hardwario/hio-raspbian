#!/bin/bash
set -eu

_step_counter=0

step() {
	_step_counter=$(( _step_counter + 1 ))
	printf '\n\033[1;36m%d) %s\033[0m\n' $_step_counter "$@" >&2  # bold cyan
}

step 'Install dependencies'
sudo apt install python3-pip
sudo -H pip3 install influxdb docopt paho-mqtt

step 'Download script'
sudo wget "https://raw.githubusercontent.com/blavka/bcp-monitor-in-docker/master/bc-mqtt-to-influxdb.py" -O /usr/bin/bc-mqtt-to-influxdb
sudo chmod +x /usr/bin/bc-mqtt-to-influxdb

step 'Add service'
sudo wget "https://raw.githubusercontent.com/blavka/bcp-monitor-in-docker/master/bc-mqtt-to-influxdb.service" -O /etc/systemd/system/bc-mqtt-to-influxdb.service

step 'Eneble service'
sudo systemctl daemon-reload
sudo systemctl enable bc-mqtt-to-influxdb.service

step 'Start service'
sudo systemctl start bc-mqtt-to-influxdb.service
