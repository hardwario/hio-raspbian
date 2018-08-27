<a href="https://www.bigclown.com/"><img src="https://bigclown.sirv.com/logo.png" width="200" alt="BigClown Logo" align="right"></a>

# BigClown Raspbian

[![Travis](https://img.shields.io/travis/bigclownlabs/bc-raspbian/master.svg)](https://travis-ci.org/bigclownlabs/bc-raspbian)
[![Release](https://img.shields.io/github/release/bigclownlabs/bc-raspbian.svg)](https://github.com/bigclownlabs/bc-raspbian/releases)
[![License](https://img.shields.io/github/license/bigclownlabs/bc-raspbian.svg)](https://github.com/bigclownlabs/bc-raspbian/blob/master/LICENSE)
[![Twitter](https://img.shields.io/twitter/follow/BigClownLabs.svg?style=social&label=Follow)](https://twitter.com/BigClownLabs)

This repository contains scripts for building customized Raspbian image for Raspberry Pi.

Prebuilt images for your Raspberry Pi are available in [Releases](https://github.com/bigclownlabs/bc-raspbian/releases) – just pick a ZIP file from the Latest release.

Installation procedure is the same as for original Raspbian image which is described [here](https://www.raspberrypi.org/documentation/installation/installing-images/).

Images are automatically built on [Travis CI](https://travis-ci.org/bigclownlabs/bc-raspbian).

## Modifications in this image

Our image is built with the same scripts as the “official” one, with the following modifications:

* Default name servers changed to: 8.8.8.8, 217.31.204.130, 2001:4860:4860::8888, 2001:1488:800:400::130.
* Hostname changed from `raspberrypi` to `hub`.
* Locale changed from `en_GB.UTF-8` to `en_US.UTF-8`.
* Keymap changed from `English (UK)` to `English (US) - English (US, international with dead keys)`.
* Timezone changed from `Etc/UTC` to `Europe/Prague`.
* OpenSSH daemon enabled by default and removed `AcceptEnv LANG LC_*`.
* Added third-party repositories:
    * https://deb.nodesource.com/node_8.x
    * http://repo.mosquitto.org/debian
* Similar installations, as described in the [documentation](https://doc.bigclown.com/tutorials/playground-setup/#playground-setup-on-ubuntu)
* Ports and services:
    * 80: port forwarding to 8080
    * 1880: Node-RED
	* 1883: Mosquitto mqtt
	* 8080: http-server (static contet from /var/www)
	* 9001: Mosquitto websocket

* Installed additional packages:
	* mosquitto
	* mosquitto-clients
	* nodejs
	* python3-pip
	* python3-venv
	* dfu-util
	* git
	* htop
	* mc
	* tmux

* Installed via npm:
	* pm2
    * node-red
	* node-red-dashboard
	* node-red-contrib-ifttt
	* http-server

* Installed via pip3:
	* bcg
	* bcf
	* bch

---

Made with &#x2764;&nbsp; by [**HARDWARIO s.r.o.**](https://www.hardwario.com/) in the heart of Europe.
