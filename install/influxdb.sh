#!/bin/bash
set -eu

_step_counter=0

step() {
	_step_counter=$(( _step_counter + 1 ))
	printf '\n\033[1;36m%d) %s\033[0m\n' $_step_counter "$@" >&2  # bold cyan
}

step 'Upgrade and Update'
sudo apt update && sudo apt upgrade -y

step 'Install dependencies'
sudo apt install apt-transport-https curl -y

step 'Add repository key'
curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -

step 'Add source list'
echo "deb https://repos.influxdata.com/debian jessie stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

step 'Install'
sudo apt update && sudo apt install influxdb

step 'Eneble service'
sudo systemctl daemon-reload
sudo systemctl enable influxdb

step 'Start service'
sudo systemctl start influxdb
