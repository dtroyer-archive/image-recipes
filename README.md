OpenStack CentOS image creation with autoresize
=============

Kickstart files and scripts for building minimal VM images for OpenStack

Features
--------

The images created will have the following features:
* minimal installs excluding the common 'base' groups
* timezone is UTC
* single root filesystem, grows to size of disk on first boot
* latest cloud-init is installed
* rng-tools is loaded to take advantage of host virt entropy if available
* build timestamp in /etc/.build

How to use
------
* create image : oz-install -d3 -a centos-6-x86_64.ks -u centos-6-x86_64.tdl -x centos64-libvirt.xml
 *               oz-install -d3 -u centos-7-x86_64.tdl -x centos-7-libvirt.xml
* open centos64-libvirt.xml to see where the image has been created
* run : virt-sysprep -a centos-6-x86_64.dsk on your image after it's created
* convert .dsk to .qcow2 : qemu-img convert -f raw -O qcow2 centos-6-x86_64.dsk centos-6-x86_64.qcow2
* OpenStack Glance import : glance image-create --name="CentOS 6.4 Final" --disk-format=qcow2 --container-format=bare < centos-6-x86_64.qcow2

Fedora
------
* login name is 'fedora'

CentOS
------
* EPEL repo is enabled
* login name is 'centos'
* postfix is installed (prereq for cronie) but not enabled
* if you use image for openstack login as root with your private key
