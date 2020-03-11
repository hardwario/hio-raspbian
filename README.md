<a href="https://www.hardwario.com/"><img src="https://www.hardwario.com/ci/assets/hw-logo.svg" width="200" alt="HARDWARIO Logo" align="right"></a>

# HARDWARIO Raspbian

[![Travis](https://img.shields.io/travis/bigclownlabs/bc-raspbian/master.svg)](https://travis-ci.org/bigclownlabs/bc-raspbian)
[![Release](https://img.shields.io/github/release/bigclownlabs/bc-raspbian.svg)](https://github.com/bigclownlabs/bc-raspbian/releases)
[![License](https://img.shields.io/github/license/bigclownlabs/bc-raspbian.svg)](https://github.com/bigclownlabs/bc-raspbian/blob/master/LICENSE)
[![Twitter](https://img.shields.io/twitter/follow/hardwario_en.svg?style=social&label=Follow)](https://twitter.com/hardwario_en)

This repository contains scripts for building customized Raspbian image for Raspberry Pi.

Prebuilt images for your Raspberry Pi are available in [Releases](https://github.com/bigclownlabs/bc-raspbian/releases) – just pick a ZIP file from the Latest release.

Installation procedure is the same as for original Raspbian image which is described [here](https://www.raspberrypi.org/documentation/installation/installing-images/).

Images are automatically built on [Travis CI](https://travis-ci.org/bigclownlabs/bc-raspbian).

## Modifications in this image

Our image is built with the same scripts as the “official” one, with the following modifications:

* Hostname changed from `raspberrypi` to `hub`.

* Added third-party repositories:
    * https://deb.nodesource.com/node_12.x
    * http://repo.mosquitto.org/debian

* Similar installations, as described in the [documentation](https://doc.bigclown.com/tutorials/playground-setup/#playground-setup-on-ubuntu)
* Ports and services:
    * 80: nginx (static contet from /var/www/html)
    * 1880: Node-RED
	* 1883: Mosquitto mqtt
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
	* node-red-contrib-blynk-ws
	* ubidots-nodered (Node Red plugin)

* Installed via pip3:
	* bcg
	* bcf
	* bch

* Static file for web interface https://github.com/bigclownlabs/bch-hub-web

---

## Local build

### Install dependencies

    sudo apt install kpartx coreutils zip qemu-user-static binfmt-support

	sudo ./build.sh


Made with &#x2764;&nbsp; by [**HARDWARIO s.r.o.**](https://www.hardwario.com/) in the heart of Europe.
