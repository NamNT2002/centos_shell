#!/bin/bash
#Script install Mysql Server on Centos

#configure default
read -p"Password controll Database Mysql:" -s dbpass
if [ $dbpass = "" ]; then
	echo "Password not none"
	exit $1
fi
echo ""
read -p"Password controll Openstack:" -s ADMIN_PASSWORD
if [ $ADMIN_PASSWORD = "" ]; then
	echo "ADMIN_PASSWORD not none"
	exit $1
fi
echo ""
dbp_keystone=`openssl rand -hex 16`
dbp_glance=`openssl rand -hex 16`
dbp_neutron=`openssl rand -hex 16`
dbp_nova=`openssl rand -hex 16`
dbp_cinder=`openssl rand -hex 16`
dbp_heat=`openssl rand -hex 16`
SERVICE_PASSWORD=`openssl rand -hex 16`
RABBIT_PASS=`openssl rand -hex 16`
METADATA_PASS=`openssl rand -hex 16`



#install packet
yum -y install mysql-server
/etc/init.d/mysqld restart
mysql_secure_installation << eof

Y
$dbpass
$dbpass
Y
Y
Y
Y
eof
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

CREATE DATABASE openstack;
use openstack;

CREATE TABLE configure_openstack (
  STT int(11) NOT NULL AUTO_INCREMENT,
  configure varchar(100) DEFAULT NULL,
  PRIMARY KEY (STT)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;

INSERT INTO configure_openstack (configure) VALUES
('export dbpass=$dbpass'),
('export ADMIN_PASSWORD=$ADMIN_PASSWORD'),
('export dbp_keystone=$dbp_keystone'),
('export dbp_glance=$dbp_glance'),
('export dbp_neutron=$dbp_neutron'),
('export dbp_nova=$dbp_nova'),
('export dbp_cinder=$dbp_cinder'),
('export dbp_heat=$dbp_heat'),
('export SERVICE_PASSWORD=$SERVICE_PASSWORD'),
('export RABBIT_PASS=$RABBIT_PASS'),
('export METADATA_PASS=$METADATA_PASS'),
('export METADATA_PASS=$METADATA_PASS'),
('export SERVICE_TOKEN="ADMIN"');
EOF
#Create Database
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
/etc/init.d/mysqld restart
/etc/init.d/iptables stop
chkconfig mysqld on
chkconfig iptables off
#cat configure_openstack.sql | mysql -u root -p$dbpass openstack
clear
echo "======================================="
echo "=         Cai dat thanh cong          ="
echo "Password database: $dbpass"
echo "Password Controller Openstack: $ADMIN_PASSWORD"
echo "======================================="