#!/bin/bash
#Script Add the dashboard
. ./configure_openstack
echo "Install Packet"
#install packet
apt-get install memcached libapache2-mod-wsgi openstack-dashboard -y
apt-get remove --purge openstack-dashboard-ubuntu-theme -y

echo "Install Success Full"
echo "De truy cap vao trang web quan tri ban ban co the vaot heo duong link sau:"
echo "Web manager: http://$HOST_IP/horizon"
echo "Username: admin 				password: $ADMIN_PASSWORD"