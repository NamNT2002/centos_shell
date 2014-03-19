#!/bin/bash
#PREPARE UBUNTU
#Add Havana repositories

source ~/config_openstack

#apt-get -y install ubuntu-cloud-keyring python-software-properties software-properties-common python-keyring

#echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-proposed/havana main >> /etc/apt/sources.li##st.d/havana.list

#update system
apt-get -y update


#MySQL, RabbitMQ, NTP
#echo "export dbpass=`openssl rand -hex 32`" >> passmysql.txt
#echo "export dbp_keystone=`openssl rand -hex 32`" >> passmysql.txt
#echo "export dbp_glance=`openssl rand -hex 32`" >> passmysql.txt
#echo "export dbp_neutron=`openssl rand -hex 32`" >> passmysql.txt
#echo "export dbp_nova=`openssl rand -hex 32`" >> passmysql.txt
#echo "export dbp_cinder=`openssl rand -hex 32`" >> passmysql.txt
#echo "export dbp_heat=`openssl rand -hex 32`" >> passmysql.txt
dbpass=`openssl rand -hex 32`
dbp_keystone=`openssl rand -hex 32`
dbp_glance=`openssl rand -hex 32`
bp_neutron=`openssl rand -hex 32`
dbp_nova=`openssl rand -hex 32`
dbp_cinder=`openssl rand -hex 32`
dbp_heat=`openssl rand -hex 32`
echo $dbpass
echo "mysql-server mysql-server/root_password password $dbpass" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $dbpass" | debconf-set-selections
apt-get -y install mysql-server