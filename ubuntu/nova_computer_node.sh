#!/bin/bash
#Install Computer Node

#install python mysql client
apt-get install python-mysqldb -y

#import ppa openstack
apt-get install python-software-properties -y
add-apt-repository cloud-archive:havana << eof



eof

apt-get update && apt-get dist-upgrade

#install nova-compute-kvm
apt-get -y install nova-compute-kvm python-guestfs
dpkg-statoverride  --update --add root root 0644 /boot/vmlinuz-$(uname -r)
mv startoverride /etc/kernel/postinst.d/statoverride
chmod +x /etc/kernel/postinst.d/statoverride