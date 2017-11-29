<a href="https://www.bigclown.com/"><img src="https://bigclown.sirv.com/logo.png" width="200" height="59" alt="BigClown Logo" align="right"></a>

# BigClown Raspbian

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
* Country in `wpa_supplicant.conf` changed from `GB` to `CZ`.
* OpenSSH daemon enabled by default and removed `AcceptEnv LANG LC_*`.
* Added third-party repositories:
    * https://deb.nodesource.com/node_6.x
    * https://repo.bigclown.com/debian
    * http://repo.mosquitto.org/debian
* Similar installations, as described in the [documentation](https://doc.bigclown.com/tutorials/playground-setup/#playground-setup-on-ubuntu)

* Installed additional packages:
	* mosquitto
	* mosquitto-clients
	* nodejs
	* python3-pip
	* python3-venv
	* git
	* htop
	* mc
	* tmux

* Installed additional packages for mosquitto, fix issue [https://github.com/eclipse/mosquitto/issues/529](https://github.com/eclipse/mosquitto/issues/529)
	* libssl1.0.0 from http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u7
	* libwebsockets3_1.2 from http://ftp.nz.debian.org/debian/pool/main/libw/libwebsockets/libwebsockets3_1.2.2-1_armhf.deb

* Installed via npm:
	* pm2
    * node-red
    * node-red-dashboard

* Installed via pip3:
	* bcg
	* bcf

---

Made with &#x2764;&nbsp; by [**HARDWARIO s.r.o.**](https://www.hardwario.com/) in the heart of Europe.
