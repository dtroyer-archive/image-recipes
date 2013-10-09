image-recipes
=============

Kickstart files and scripts for building minimal VM images.

Features
--------

The images created will have the following features:
* minimal installs excluding the common 'base' groups
* timezone is UTC
* single root filesystem, grows to size of disk on first boot
* cloud-init is installed
* rng-tools is loaded to take advantage of host virt entropy if available
* build timestamp in /etc/.build

Fedora
------
* login name is 'fedora'

CentOS
------
* EPEL repo is enabled
* login name is 'centos'
* postfix is installed (prereq for cronie) but not enabled
* it's better if you run virt-sysprep -a centos-6-x86_64.dsk on your image after it's created
* if you use image for openstack login as root with your private key
