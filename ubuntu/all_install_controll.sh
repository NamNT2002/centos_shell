#!/bin/bash
#Script All install controll node
#!/bin/bash
#Script Install OpenStack On Centos.

/sbin/ifconfig |grep -B1 "inet addr" |awk '{ if ( $1 == "inet" ) { print $2 } else if ( $2 == "Link" ) { printf "%s:" ,$1 } }' |awk -F: '{ print $1 ": " $3 }' | sed '/^\lo/d' >> allip.txt
#HOST_IP=`ifconfig $inter | grep inet | awk '{print $2}' | sed 's/addr://'`
#EXT_HOST_IP=`ifconfig $exten | grep inet | awk '{print $2}' | sed 's/addr://'`
DF_GATEWAY=`route -n | grep 'UG[ \t]' | awk '{print $2}'`
#idf=`route -n | grep 'UG[ \t]' | awk '{print $8}'`
#SUB_HOST=`route -n | grep $inter | grep 'U[ \t]' | awk '{print $3}'`
#SUB_EXT=`route -n | grep $exten | grep 'U[ \t]' | awk '{print $3}'`
#Genmask
echo "Shell configure Network On Ubuntu"
echo
echo "Dia chi IP hien tai:"
cat allip.txt
echo
echo "Default Gateway: $DF_GATEWAY"
echo
echo
rm -rf allip.txt
	inter="eth0"
	#echo "Ten Cong Internal:"
	read -p "Ten Cong Internal:" inter
	if [ "$inter" = "" ]; then
		inter="eth0"
	fi
	read -p "IP Address Internal:" HOST_IP
	if [ "$HOST_IP" = "" ]; then
		echo "IP Address Sai Cu Phap"
	fi
	read -p "Subnet Internal:" SUB_HOST
	if [ "$SUB_HOST" = "" ]; then
		echo "Subnet Mask Sai Cu Phap"
	fi
	echo ""
	echo ""
	exten="eth1"
	#echo "Ten Cong External:"
	read -p "Ten Cong External:" exten
	if [ "$exten" = "" ]; then
		exten="eth1"
	fi
	read -p "IP Address External:" EXT_HOST_IP
	if [ "$EXT_HOST_IP" = "" ]; then
		echo "IP Address Sai Cu Phap"
	fi
	read -p "Subnet Mask External:" SUB_EXT
	if [ "$SUB_EXT" = "" ]; then
		echo "Subnet Mask Sai Cu Phap"
	fi
	read -p "Default Gateway External:" DF_GATEWAY
	if [ "$DF_GATEWAY" = "" ]; then
		echo "Default Gateway Sai Cu Phap"
	fi
#echo "Default Gateway: Interface " $idf " Ip Address:" $DF_GATEWAY
#echo "subnet: " $SUB_HOST
#echo "SuB EXT: " $SUB_EXT
InterfaceFile=/etc/network/interfaces
cat > $InterfaceFile <<EOF
# Localhost
auto lo
iface lo inet loopback
# Not Internet connected (OpenStack management network)
auto $inter
iface $inter inet static
   address $HOST_IP
   netmask $SUB_HOST
#
auto $exten
iface $exten inet static
   address $EXT_HOST_IP
   netmask $SUB_EXT
   gateway $DF_GATEWAY
   dns-nameservers 8.8.8.8
EOF
echo "Restart network"
echo "Waiting ..... "
sleep 3
/etc/init.d/networking restart
#clear
#echo "Change Configure Interface Success Full"
#echo "Internal interface $inter" IP ADDR:$HOST_IP " - Subnet Mask:" $SUB_HOST
#echo "External interface $exten" IP ADDR:$EXT_HOST_IP " - Subnet Mask:" $SUB_EXT " - Default Gateway:" $DF_GATEWAY
#echo "HOST_IP=`ifconfig eth1 | grep inet | awk '{print $2}' | sed 's/addr://'`" >> /root/config_openstack
#echo "EXT_HOST_IP=`ifconfig eth0 | grep inet | awk '{print $2}' | sed 's/addr://'`" >> /root/config_openstack
#chmod +x /root/config_openstack
export SERVICE_TOKEN="ADMIN"
export SERVICE_ENDPOINT="http://$HOST_IP:35357/v2.0"
rm -rf configure_openstack
echo "HOST_IP=$HOST_IP" >> configure_openstack
echo "EXT_HOST_IP=$EXT_HOST_IP" >> configure_openstack
dbpass=`openssl rand -hex 16`
dbp_keystone=`openssl rand -hex 16`
dbp_glance=`openssl rand -hex 16`
dbp_neutron=`openssl rand -hex 16`
dbp_nova=`openssl rand -hex 16`
dbp_cinder=`openssl rand -hex 16`
dbp_heat=`openssl rand -hex 16`
ADMIN_PASSWORD=`openssl rand -hex 16`
SERVICE_PASSWORD=`openssl rand -hex 16`
RABBIT_PASS=`openssl rand -hex 16`
METADATA_PASS=`openssl rand -hex 16`
echo RABBIT_PASS=$RABBIT_PASS >> configure_openstack
echo METADATA_PASS=$METADATA_PASS >> configure_openstack
echo ADMIN_PASSWORD=$ADMIN_PASSWORD >> configure_openstack
echo SERVICE_PASSWORD=$SERVICE_PASSWORD >> configure_openstack
echo SERVICE_TOKEN=$SERVICE_TOKEN >> configure_openstack
echo SERVICE_ENDPOINT=$SERVICE_ENDPOINT >> configure_openstack
echo dbpass=$dbpass >> configure_openstack
echo dbp_keystone=$dbp_keystone >> configure_openstack
echo dbp_glance=$dbp_glance >> configure_openstack
echo dbp_neutron=$dbp_neutron >> configure_openstack
echo dbp_nova=$dbp_nova >> configure_openstack
echo dbp_cinder=$dbp_cinder >> configure_openstack
echo dbp_heat=$dbp_heat >> configure_openstack
chmod +x configure_openstack


#acac
#!/bin/bash
#PREPARE UBUNTU
#Add Havana repositories

#. ./configure_openstack

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
#echo "Thong Tin mat khau"
#cat Openstack_password
#echo $HOST_IP
#echo $EXT_HOST_IP

#keystone

#!/bin/bash
#Install Keystone


export SERVICE_TOKEN="ADMIN"
export SERVICE_ENDPOINT="http://$HOST_IP:35357/v2.0"
echo "export SERVICE_TOKEN=ADMIN" >> source_openstack
echo "export SERVICE_ENDPOINT=http://$HOST_IP:35357/v2.0" >> source_openstack
SERVICE_TENANT_NAME=${SERVICE_TENANT_NAME:-service}
echo "Import PPA OpenStack"
sleep 3
apt-get -y install python-software-properties
add-apt-repository cloud-archive:havana<<eof



eof
apt-get -y update && apt-get -y dist-upgrade
clear
echo "Install Rabit messaging"
sleep 2

apt-get -y install rabbitmq-server
rabbitmqctl change_password guest $RABBIT_PASS
clear
echo "Install Rabit Messaging Success"
echo "Install Keystone"
apt-get -y install keystone
#sed -i 's|connection = sqlite:////var/lib/keystone/keystone.db|connection = mysql://keystone:[$dbp_keystone]@[$HOST_IP]/keystone |g' /etc/keystone/keystone.conf
sed '/^\connection = sqlite/d' /etc/keystone/keystone.conf >> keystoneconf
mv /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bk
sed '/^\[sql]/d' keystoneconf >> keystoneconf1
rm -rf keystoneconf
sed '/^\#/d' keystoneconf1 >> /etc/keystone/keystone.conf
rm -rf keystoneconf1
echo "[sql]" >> /etc/keystone/keystone.conf
echo "connection = mysql://keystone:$dbp_keystone@$HOST_IP/keystone" >> /etc/keystone/keystone.conf
rm -rf rm /var/lib/keystone/keystone.db
#sync db keystone
echo "Restart Keystone"
/etc/init.d/keystone restart
keystone-manage db_sync

get_id () {
    echo `$@ | awk '/ id / { print $4 }'`
}
# Tenants
keystone tenant-create --name admin
keystone tenant-create --name service

# Users
keystone user-create --name admin --pass "$ADMIN_PASSWORD" --email admin@domain.com

# Roles
keystone role-create --name Member
keystone role-create --name admin
keystone role-create --name KeystoneAdmin
keystone role-create --name KeystoneServiceAdmin
keystone role-create --name ResellerAdmin

# Users
keystone user-create --name nova --pass "$SERVICE_PASSWORD" --email nova@domain.com
keystone user-create --name glance --pass "$SERVICE_PASSWORD" --email glance@domain.com
keystone user-create --name neutron --pass "$SERVICE_PASSWORD" --email neutron@domain.com
#keystone user-create --name cinder --pass "$SERVICE_PASSWORD" --email cinder@domain.com
#keystone user-create --name swift --pass "$SERVICE_PASSWORD" --email swift@domain.com
#keystone user-create --name ceilometer --pass "$SERVICE_PASSWORD" --email ceilometer@domain.com
#keystone user-create --name heat --pass "$SERVICE_PASSWORD" --email heat@domain.com

# Roles
keystone user-role-add --tenant admin --user admin --role admin 
keystone user-role-add --tenant admin --user admin --role KeystoneAdmin
keystone user-role-add --tenant admin --user admin --role KeystoneServiceAdmin

keystone user-role-add --tenant service --user nova --role admin
keystone user-role-add --tenant service --user glance --role admin
keystone user-role-add --tenant service --user neutron --role admin
#keystone user-role-add --tenant service --user cinder --role admin
#keystone user-role-add --tenant service --user swift --role admin
#keystone user-role-add --tenant service --user ceilometer --role admin
#keystone user-role-add --tenant service --user ceilometer --role ResellerAdmin
#keystone user-role-add --tenant service --user heat --role admin

# Services
NOVA_SERVICE=$(get_id keystone service-create --name nova --type compute --description Compute)
#CINDER_SERVICE=$(get_id keystone service-create --name cinder --type volume --description Volume)
GLANCE_SERVICE=$(get_id keystone service-create --name glance --type image --description Image)
KEYSTONE_SERVICE=$(get_id keystone service-create --name keystone --type identity --description Identity)
EC2_SERVICE=$(get_id keystone service-create --name ec2 --type ec2 --description EC2)
NEUTRON_SERVICE=$(get_id keystone service-create --name neutron --type network --description Networking)
#SWIFT_SERVICE=$(get_id keystone service-create --name swift --type object-store --description Storage)
#CEILOMETER_SERVICE=$(get_id keystone service-create --name ceilometer --type metering --description Metering)
#HEAT_SERVICE=$(get_id keystone service-create --name heat --type orchestration --description Orchestration)
#CFN_SERVICE=$(get_id keystone service-create --name heat-cfn --type cloudformation --description Cloudformation)

# Service endpoints
keystone endpoint-create --region RegionOne --service-id $NOVA_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8774/v2/$(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8774/v2/$(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8774/v2/$(tenant_id)s'
#keystone endpoint-create --region RegionOne --service-id $CINDER_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8776/v1/$(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8776/v1/$(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8776/v1/$(tenant_id)s'
keystone endpoint-create --region RegionOne --service-id $GLANCE_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':9292/v2' --adminurl 'http://'"$HOST_IP"':9292/v2' --internalurl 'http://'"$HOST_IP"':9292/v2'
keystone endpoint-create --region RegionOne --service-id $KEYSTONE_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':5000/v2.0' --adminurl 'http://'"$HOST_IP"':35357/v2.0' --internalurl 'http://'"$HOST_IP"':5000/v2.0'
keystone endpoint-create --region RegionOne --service-id $EC2_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8773/services/Cloud' --adminurl 'http://'"$HOST_IP"':8773/services/Admin' --internalurl 'http://'"$HOST_IP"':8773/services/Cloud'
keystone endpoint-create --region RegionOne --service-id $NEUTRON_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':9696' --adminurl 'http://'"$HOST_IP"':9696' --internalurl 'http://'"$HOST_IP"':9696'
#keystone endpoint-create --region RegionOne --service-id $SWIFT_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8080/v1/AUTH_%(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8080' --internalurl 'http://'"$HOST_IP"':8080/v1/AUTH_%(tenant_id)s'
#keystone endpoint-create --region RegionOne --service-id $CEILOMETER_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8777' --adminurl 'http://'"$HOST_IP"':8777' --internalurl 'http://'"$HOST_IP"':8777'
#keystone endpoint-create --region RegionOne --service-id $HEAT_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8004/v1/$(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8004/v1/$(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8004/v1/$(tenant_id)s'
#keystone endpoint-create --region RegionOne --service-id $CFN_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8000/v1' --adminurl 'http://'"$HOST_IP"':8000/v1' --internalurl 'http://'"$HOST_IP"':8000/v1'

echo "Install Success Full"
#echo `keystone endpoint-list`

#glance

#!/bin/bash
#Script Install Image Service

apt-get -y install glance python-glanceclient
clear
echo "Install Packet success ...."
echo "Waiting configure Glance"
sleep 5
mv /etc/glance/glance-api.conf /etc/glance/glance-api.conf.bk
mv /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.bk
mv /etc/glance/glance-registry-paste.ini /etc/glance/glance-registry-paste.ini.bk
mv /etc/glance/glance-api-paste.ini /etc/glance/glance-api-paste.ini.bk
echo "Setup glan-api.conf"
cat > /etc/glance/glance-api.conf <<eof
[DEFAULT]
default_store = file
bind_host = 0.0.0.0
bind_port = 9292
log_file = /var/log/glance/api.log
backlog = 4096
sql_connection = mysql://glance:$dbp_glance@$HOST_IP/glance
sql_idle_timeout = 3600
workers = 1
registry_host = 0.0.0.0
registry_port = 9191
registry_client_protocol = http
notifier_strategy = noop
rabbit_host = $HOST_IP
rabbit_port = 5672
rabbit_use_ssl = false
rabbit_userid = guest
rabbit_password = $RABBIT_PASS
rabbit_virtual_host = /
rabbit_notification_exchange = glance
rabbit_notification_topic = notifications
rabbit_durable_queues = False
qpid_notification_exchange = glance
qpid_notification_topic = notifications
qpid_hostname = localhost
qpid_port = 5672
qpid_username =
qpid_password =
qpid_sasl_mechanisms =
qpid_reconnect_timeout = 0
qpid_reconnect_limit = 0
qpid_reconnect_interval_min = 0
qpid_reconnect_interval_max = 0
qpid_reconnect_interval = 0
qpid_heartbeat = 5
qpid_protocol = tcp
qpid_tcp_nodelay = True
filesystem_store_datadir = /var/lib/glance/images/
swift_store_auth_version = 2
swift_store_auth_address = 127.0.0.1:5000/v2.0/
swift_store_user = jdoe:jdoe
swift_store_key = a86850deb2742ec3cb41518e26aa2d89
swift_store_container = glance
swift_store_create_container_on_put = False
swift_store_large_object_size = 5120
swift_store_large_object_chunk_size = 200
swift_enable_snet = False
s3_store_host = 127.0.0.1:8080/v1.0/
s3_store_access_key = <20-char AWS access key>
s3_store_secret_key = <40-char AWS secret key>
s3_store_bucket = <lowercased 20-char aws access key>glance
s3_store_create_bucket_on_put = False
rbd_store_ceph_conf = /etc/ceph/ceph.conf
rbd_store_user = glance
rbd_store_pool = images
rbd_store_chunk_size = 8
sheepdog_store_address = localhost
sheepdog_store_port = 7000
sheepdog_store_chunk_size = 64
delayed_delete = False
scrub_time = 43200
scrubber_datadir = /var/lib/glance/scrubber
image_cache_dir = /var/lib/glance/image-cache/
[keystone_authtoken]
auth_host = $HOST_IP
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = glance
admin_password = $SERVICE_PASSWORD
[paste_deploy]
flavor = keystone
eof

echo "Setup glance-registry.conf"
cat > /etc/glance/glance-registry.conf <<eof
[DEFAULT]
bind_host = 0.0.0.0
bind_port = 9191
log_file = /var/log/glance/registry.log
backlog = 4096
sql_connection = mysql://glance:$dbp_glance@$HOST_IP/glance
sql_idle_timeout = 3600
api_limit_max = 1000
limit_param_default = 25
[keystone_authtoken]
auth_host = $HOST_IP
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = glance
admin_password = $SERVICE_PASSWORD
[paste_deploy]
flavor = keystone
eof

echo "configure glance-registry-paste.ini"
cat > /etc/glance/glance-registry-paste.ini << eof
[pipeline:glance-registry]
pipeline = unauthenticated-context registryapp
[pipeline:glance-registry-keystone]
pipeline = authtoken context registryapp
[pipeline:glance-registry-trusted-auth]
pipeline = context registryapp
[app:registryapp]
paste.app_factory = glance.registry.api.v1:API.factory
[filter:context]
paste.filter_factory = glance.api.middleware.context:ContextMiddleware.factory
[filter:unauthenticated-context]
paste.filter_factory = glance.api.middleware.context:UnauthenticatedContextMiddleware.factory
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
admin_password = $SERVICE_PASSWORD
admin_user = glance
admin_tenant_name = service
auth_protocol = http
auth_port = 35357
auth_host = $HOST_IP
eof

echo "configure glance-api-paste.ini"
cat > /etc/glance/glance-api-paste.ini << eof
[pipeline:glance-api]
pipeline = versionnegotiation unauthenticated-context rootapp
[pipeline:glance-api-caching]
pipeline = versionnegotiation unauthenticated-context cache rootapp
[pipeline:glance-api-cachemanagement]
pipeline = versionnegotiation unauthenticated-context cache cachemanage rootapp
[pipeline:glance-api-keystone]
pipeline = versionnegotiation authtoken context rootapp
[pipeline:glance-api-keystone+caching]
pipeline = versionnegotiation authtoken context cache rootapp
[pipeline:glance-api-keystone+cachemanagement]
pipeline = versionnegotiation authtoken context cache cachemanage rootapp
[pipeline:glance-api-trusted-auth]
pipeline = versionnegotiation context rootapp
[pipeline:glance-api-trusted-auth+cachemanagement]
pipeline = versionnegotiation context cache cachemanage rootapp
[composite:rootapp]
paste.composite_factory = glance.api:root_app_factory
/: apiversions
/v1: apiv1app
/v2: apiv2app
[app:apiversions]
paste.app_factory = glance.api.versions:create_resource
[app:apiv1app]
paste.app_factory = glance.api.v1.router:API.factory
[app:apiv2app]
paste.app_factory = glance.api.v2.router:API.factory
[filter:versionnegotiation]
paste.filter_factory = glance.api.middleware.version_negotiation:VersionNegotiationFilter.factory
[filter:cache]
paste.filter_factory = glance.api.middleware.cache:CacheFilter.factory
[filter:cachemanage]
paste.filter_factory = glance.api.middleware.cache_manage:CacheManageFilter.factory
[filter:context]
paste.filter_factory = glance.api.middleware.context:ContextMiddleware.factory
[filter:unauthenticated-context]
paste.filter_factory = glance.api.middleware.context:UnauthenticatedContextMiddleware.factory
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
admin_password = $SERVICE_PASSWORD
admin_user = glance
admin_tenant_name = service
auth_protocol = http
auth_port = 35357
auth_host = $HOST_IP
delay_auth_decision = true
[filter:gzip]
paste.filter_factory = glance.api.middleware.gzip:GzipMiddleware.factory
eof
rm -rf /var/lib/glance/glance.sqlite
/etc/init.d/glance-api restart && /etc/init.d/glance-registry restart
glance-manage db_sync
/etc/init.d/glance-api restart && /etc/init.d/glance-registry restart
echo "Install Glance Success Full"

#!/bin/bash
#Install Compute controller services
#nova

echo "Istall packet"
sleep 5
apt-get -y install nova-novncproxy novnc nova-api nova-ajax-console-proxy nova-cert nova-conductor nova-consoleauth nova-doc nova-scheduler python-novaclient
clear
cd /etc/init.d/; for i in $( ls nova-* ); do service $i restart; cd; done
echo "Install success"
echo "Configure Nove Server"
sleep 5
mv /etc/nova/nova.conf /etc/nova/nova.conf.bk
mv /etc/nova/api-paste.ini /etc/nova/api-paste.ini.bk
cat > /etc/nova/nova.conf << eof
[DEFAULT]
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
iscsi_helper=tgtadm
libvirt_use_virtio_for_bridges=True
connection_type=libvirt
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf
verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
volumes_path=/var/lib/nova/volumes
enabled_apis=ec2,osapi_compute,metadata

rpc_backend = nova.rpc.impl_kombu
rabbit_host = $HOST_IP
rabbit_password = $RABBIT_PASS

my_ip=$EXT_HOST_IP
vncserver_listen=$EXT_HOST_IP
vncserver_proxyclient_address=$EXT_HOST_IP

auth_strategy=keystone

neutron_metadata_proxy_shared_secret = $METADATA_PASS
service_neutron_metadata_proxy = true

network_api_class=nova.network.neutronv2.api.API
neutron_url=http://$HOST_IP:9696
neutron_auth_strategy=keystone
neutron_admin_tenant_name=service
neutron_admin_username=neutron
neutron_admin_password=$SERVICE_PASSWORD
neutron_admin_auth_url=http://$HOST_IP:35357/v2.0
linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver=nova.virt.firewall.NoopFirewallDriver
security_group_api=neutron


[database]
# The SQLAlchemy connection string used to connect to the database
connection = mysql://nova:$dbp_nova@$HOST_IP/nova
[keystone_authtoken]
auth_host = $HOST_IP
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = nova
admin_password = $SERVICE_PASSWORD
eof

cat > /etc/nova/api-paste.ini << eof
[composite:metadata]
use = egg:Paste#urlmap
/: meta
[pipeline:meta]
pipeline = ec2faultwrap logrequest metaapp
[app:metaapp]
paste.app_factory = nova.api.metadata.handler:MetadataRequestHandler.factory
[composite:ec2]
use = egg:Paste#urlmap
/services/Cloud: ec2cloud
[composite:ec2cloud]
use = call:nova.api.auth:pipeline_factory
noauth = ec2faultwrap logrequest ec2noauth cloudrequest validator ec2executor
keystone = ec2faultwrap logrequest ec2keystoneauth cloudrequest validator ec2executor
[filter:ec2faultwrap]
paste.filter_factory = nova.api.ec2:FaultWrapper.factory
[filter:logrequest]
paste.filter_factory = nova.api.ec2:RequestLogging.factory
[filter:ec2lockout]
paste.filter_factory = nova.api.ec2:Lockout.factory
[filter:ec2keystoneauth]
paste.filter_factory = nova.api.ec2:EC2KeystoneAuth.factory
[filter:ec2noauth]
paste.filter_factory = nova.api.ec2:NoAuth.factory
[filter:cloudrequest]
controller = nova.api.ec2.cloud.CloudController
paste.filter_factory = nova.api.ec2:Requestify.factory
[filter:authorizer]
paste.filter_factory = nova.api.ec2:Authorizer.factory
[filter:validator]
paste.filter_factory = nova.api.ec2:Validator.factory
[app:ec2executor]
paste.app_factory = nova.api.ec2:Executor.factory
[composite:osapi_compute]
use = call:nova.api.openstack.urlmap:urlmap_factory
/: oscomputeversions
/v1.1: openstack_compute_api_v2
/v2: openstack_compute_api_v2
/v3: openstack_compute_api_v3
[composite:openstack_compute_api_v2]
use = call:nova.api.auth:pipeline_factory
noauth = faultwrap sizelimit noauth ratelimit osapi_compute_app_v2
keystone = faultwrap sizelimit authtoken keystonecontext ratelimit osapi_compute_app_v2
keystone_nolimit = faultwrap sizelimit authtoken keystonecontext osapi_compute_app_v2
[composite:openstack_compute_api_v3]
use = call:nova.api.auth:pipeline_factory
noauth = faultwrap sizelimit noauth_v3 ratelimit_v3 osapi_compute_app_v3
keystone = faultwrap sizelimit authtoken keystonecontext ratelimit_v3 osapi_compute_app_v3
keystone_nolimit = faultwrap sizelimit authtoken keystonecontext osapi_compute_app_v3
[filter:faultwrap]
paste.filter_factory = nova.api.openstack:FaultWrapper.factory
[filter:noauth]
paste.filter_factory = nova.api.openstack.auth:NoAuthMiddleware.factory
[filter:noauth_v3]
paste.filter_factory = nova.api.openstack.auth:NoAuthMiddlewareV3.factory
[filter:ratelimit]
paste.filter_factory = nova.api.openstack.compute.limits:RateLimitingMiddleware.factory
[filter:ratelimit_v3]
paste.filter_factory = nova.api.openstack.compute.plugins.v3.limits:RateLimitingMiddleware.factory
[filter:sizelimit]
paste.filter_factory = nova.api.sizelimit:RequestBodySizeLimiter.factory
[app:osapi_compute_app_v2]
paste.app_factory = nova.api.openstack.compute:APIRouter.factory
[app:osapi_compute_app_v3]
paste.app_factory = nova.api.openstack.compute:APIRouterV3.factory
[pipeline:oscomputeversions]
pipeline = faultwrap oscomputeversionapp
[app:oscomputeversionapp]
paste.app_factory = nova.api.openstack.compute.versions:Versions.factory
[filter:keystonecontext]
paste.filter_factory = nova.api.auth:NovaKeystoneContext.factory
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
auth_host = $HOST_IP
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = nova
admin_password = $SERVICE_PASSWORD
auth_version = v2.0
eof
echo "Restart nova"
sleep 5
cd /etc/init.d/; for i in $( ls nova-* ); do service $i restart; cd; done
echo "Sync DB Nova"
sleep 3
nova-manage db sync
echo "Restart Nova"
cd /etc/init.d/; for i in $( ls nova-* ); do service $i restart; cd; done

#neutron controller

#!/bin/bash
#script configure neutron on controller

apt-get -y install neutron-server neutron-plugin-openvswitch
METADATA_PASS=`openssl rand -hex 16`
echo "METADATA_PASS=$METADATA_PASS" >> source_openstack

#configure /etc/nova/nova.conf
#[DEFAULT]
#neutron_metadata_proxy_shared_secret = $METADATA_PASS
#service_neutron_metadata_proxy = true

#configure /etc/neutron/neutron.conf
mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bk
cat > /etc/neutron/neutron.conf << eof

[DEFAULT]
state_path = /var/lib/neutron
lock_path = $state_path/lock
core_plugin = neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2
notification_driver = neutron.openstack.common.notifier.rpc_notifier
auth_strategy = keystone
rpc_backend = neutron.openstack.common.rpc.impl_kombu
rabbit_host = $HOST_IP
rabbit_port = 5672
rabbit_password = $RABBIT_PASS
[quotas]
[agent]
root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf
[keystone_authtoken]
auth_host = $HOST_IP
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = neutron
admin_password = $SERVICE_PASSWORD
auth_url = http://$HOST_IP:35357/v2.0
#signing_dir = $state_path/keystone-signing
[database]
connection = mysql://neutron:$dbp_neutron@$HOST_IP/neutron
[service_providers]
service_provider=LOADBALANCER:Haproxy:neutron.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default
eof

#configure /etc/neutron/api-paste.ini
mv /etc/neutron/api-paste.ini /etc/neutron/api-paste.ini.bk
cat > /etc/neutron/api-paste.ini << eof
[composite:neutron]
use = egg:Paste#urlmap
/: neutronversions
/v2.0: neutronapi_v2_0
[composite:neutronapi_v2_0]
use = call:neutron.auth:pipeline_factory
noauth = extensions neutronapiapp_v2_0
keystone = authtoken keystonecontext extensions neutronapiapp_v2_0
[filter:keystonecontext]
paste.filter_factory = neutron.auth:NeutronKeystoneContext.factory
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
admin_tenant_name = service
admin_user = neutron
admin_password = $SERVICE_PASSWORD
[filter:extensions]
paste.filter_factory = neutron.api.extensions:plugin_aware_extension_middleware_factory
[app:neutronversions]
paste.app_factory = neutron.api.versions:Versions.factory
[app:neutronapiapp_v2_0]
paste.app_factory = neutron.api.v2.router:APIRouter.factory
eof

#configure /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini
mv /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini.bk
cat > /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini << eof
[ovs]
#tenant_network_type = gre
#tunnel_id_ranges = 1:1000
#enable_tunneling = True
network_vlan_ranges = physnet1
bridge_mappings = physnet1:br-int
[agent]
[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
eof

service nova-api restart

####configure nova.conf
#network_api_class=nova.network.neutronv2.api.API
#neutron_url=http://$HOST_IP:9696
#neutron_auth_strategy=keystone
#eutron_admin_tenant_name=service
#eutron_admin_username=neutron
#eutron_admin_password=$SERVICE_PASSWORD
#neutron_admin_auth_url=http://$HOST_IP:35357/v2.0
#linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
#irewall_driver=nova.virt.firewall.NoopFirewallDriver
#ecurity_group_api=neutron
echo "Restart Nova"
cd /etc/init.d/; for i in $( ls nova-* ); do service $i restart; cd; done

apt-get install memcached libapache2-mod-wsgi openstack-dashboard -y
apt-get remove --purge openstack-dashboard-ubuntu-theme -y
sleep 5
cd /etc/init.d/; for i in $( ls neutron-* ); do service $i restart; cd; done
echo "Install Success Full"
echo "De truy cap vao trang web quan tri ban ban co the vaot heo duong link sau:"
echo "Web manager: http://$HOST_IP/horizon"
echo "Username: admin 	password: $ADMIN_PASSWORD"