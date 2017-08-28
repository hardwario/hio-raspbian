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
sudo apt install adduser libfontconfig -y

step 'Download deb'
wget $(wget "https://api.github.com/repos/fg2it/grafana-on-raspberry/releases/latest" -q -O - | grep browser_download_url | grep armhf.deb | head -n 1 | cut -d '"' -f 4) -O /tmp/grafana.deb

step 'Install'
sudo dpkg -i /tmp/grafana.deb

step 'Remove deb'
rm /tmp/grafana.deb

step 'Eneble service'
sudo systemctl daemon-reload
sudo systemctl enable grafana-server

step 'Start service'
sudo systemctl start grafana-server

step 'Done'

IP=$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')
echo "Grafana run on http://$IP:3000"
