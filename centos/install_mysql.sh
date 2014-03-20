#!/bin/bash
#PREPARE UBUNTU
#Add Havana repositories

. ./configure_openstack

#apt-get -y install ubuntu-cloud-keyring python-software-properties software-properties-common python-keyring

#echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-proposed/havana main >> /etc/apt/sources.list.d/havana.list

#update system
apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade

#MySQL, RabbitMQ, NTP
#echo "export dbpass=`openssl rand -hex 32`" >> configure_openstack
#echo "export dbp_keystone=`openssl rand -hex 32`" >> configure_openstack
#echo "export dbp_glance=`openssl rand -hex 32`" >> configure_openstack
#echo "export dbp_neutron=`openssl rand -hex 32`" >> configure_openstack
#echo "export dbp_nova=`openssl rand -hex 32`" >> configure_openstack
#echo "export dbp_cinder=`openssl rand -hex 32`" >> configure_openstack
#echo "export dbp_heat=`openssl rand -hex 32`" >> configure_openstack
dbpass=`openssl rand -hex 16`
dbp_keystone=`openssl rand -hex 16`
dbp_glance=`openssl rand -hex 16`
dbp_neutron=`openssl rand -hex 16`
dbp_nova=`openssl rand -hex 16`
dbp_cinder=`openssl rand -hex 16`
dbp_heat=`openssl rand -hex 16`
#echo $dbpass
echo "mysql-server mysql-server/root_password password $dbpass" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $dbpass" | debconf-set-selections
apt-get install -y mysql-server python-mysqldb


# Replace 127.0.0.1 by 0.0.0.0 for sql connect to all interface
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
service mysql restart

# Databases set up 
mysql -u root -p$dbpass << EOF

GRANT USAGE ON *.* TO root@'%' IDENTIFIED BY '$dbpass';
UPDATE mysql.user SET Password=PASSWORD('$dbpass') WHERE User='root';
delete from mysql.user where user=''; 
GRANT ALL PRIVILEGES ON * . * TO  'root'@'%' WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;

CREATE DATABASE keystone;
GRANT ALL ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$dbp_keystone';
GRANT ALL ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$dbp_keystone';

CREATE DATABASE glance;
GRANT ALL ON glance.* TO 'glance'@'%' IDENTIFIED BY '$dbp_glance';
GRANT ALL ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$dbp_glance';

CREATE DATABASE neutron;
GRANT ALL ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$dbp_neutron';
GRANT ALL ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$dbp_neutron';

CREATE DATABASE nova;
GRANT ALL ON nova.* TO 'nova'@'%' IDENTIFIED BY '$dbp_nova';
GRANT ALL ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$dbp_nova';

CREATE DATABASE cinder;
GRANT ALL ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$dbp_cinder';
GRANT ALL ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$dbp_cinder';

CREATE DATABASE heat;
GRANT ALL ON heat.* TO 'heat'@'%' IDENTIFIED BY '$dbp_heat';
GRANT ALL ON heat.* TO 'heat'@'localhost' IDENTIFIED BY '$dbp_heat';
EOF

echo "Chuan bi khoi dong lai MySQL"
/etc/init.d/mysql restart
#Enable IP Forwarding:
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl net.ipv4.ip_forward=1
sysctl -p
echo dbpass=$dbpass >> configure_openstack
echo dbp_keystone=$dbp_keystone >> configure_openstack
echo dbp_glance=$dbp_glance >> configure_openstack
echo dbp_neutron=$dbp_neutron >> configure_openstack
echo dbp_nova=$dbp_nova >> configure_openstack
echo dbp_cinder=$dbp_cinder >> configure_openstack
echo dbp_heat=$dbp_heat >> configure_openstack
echo "Mat Khau User Root: $dbpass" >> Openstack_password
echo "Mat Khau User keystone: $dbp_keystone" >> Openstack_password
echo "Mat Khau User glance: $dbp_glance" >> Openstack_password
echo "Mat Khau User neutron: $dbp_neutron" >> Openstack_password
echo "Mat Khau User nova: $dbp_nova" >> Openstack_password
echo "Mat Khau User cinder: $dbp_cinder" >> Openstack_password
echo "Mat Khau User heat: $dbp_heat" >> Openstack_password
#chmod +x Openstack_password
clear
echo "Cai Dat MySQL Success"
echo "Thong Tin mat khau"
cat Openstack_password
echo $HOST_IP
echo $EXT_HOST_IP
