#!/bin/bash
#Install Keystone
. ./configure_openstack
echo "Import PPA OpenStack"
sleep 3
apt-get -y install python-software-properties
add-apt-repository cloud-archive:havana<<eof



eof
apt-get -y update && apt-get -y dist-upgrade
clear
echo "Install Rabit messaging"
sleep 2
$RABBIT_PASS=`openssl rand -hex 16`
echo RABBIT_PASS=$RABBIT_PASS >> configure_openstack
apt-get -y install rabbitmq-server
rabbitmqctl change_password guest $RABBIT_PASS
clear
echo "Install Rabit Messaging Success"
echo "Install Keystone"
apt-get -y install keystone
sed -i 's|connection = sqlite:////var/lib/keystone/keystone.db|connection = mysql://keystone:openstacktest@10.10.10.51/keystone |g' /etc/keystone/keystone.conf