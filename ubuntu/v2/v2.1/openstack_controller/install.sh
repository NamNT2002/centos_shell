#!/bin/bash
#Install Controller
dir=`pwd`
InterfaceFile=/etc/network/interfaces
read -p"Ip address MySQL Server: " IP_MYSQL
read -p"Password User Root MySQL: " DBP
echo
apt-get update && apt-get -y upgrade && apt-get dist-upgrade
apt-get -y install mysql-client python-mysqldb
echo "select configure from configure_openstack" | mysql -u root -p$DBP -h$IP_MYSQL openstack > $dir/list.txt && sed -n '1!p' $dir/list.txt > $dir/configure_openstack && chmod +x $dir/configure_openstack && rm -rf $dir/list.txt
clear



all_int=`ip link show | grep BROADCAST | awk '{print $2;}' | sed 's/://'`
echo "======================================================================="
for interface in $all_int;
do ipadd=`/sbin/ifconfig $interface | grep inet | awk '{print $2}' | sed 's/addr://'`
netmask=`ifconfig $interface | grep Mask | awk '{print $4;}' | sed 's/Mask://'`
mac_int=`ip link show $interface | grep link/ether | awk '{print $2;}'`
echo "interface $interface"
echo "Dia Chi IP: $ipadd  -  Subnet Mask: $netmask "
echo "$interface MAC ADDRESS: $mac_int"
echo "=======================================================================";
done
DF_GATEWAY=`route -n | grep 'UG[ \t]' | awk '{print $2, $8}'`
echo "Default gateway $DF_GATEWAY" 

echo "Configure Interface Internal"
sh $dir/network/int_internal
sh $dir/network/int_ip_internal
sh $dir/network/int_sub_internal
echo ""
echo "Configure Interface External"
sh $dir/network/int_extenal
sh $dir/network/int_ip_external
sh $dir/network/int_sub_external
sh $dir/network/int_ext_gateway
cd $dir

#source configure openstack_confiugre
. ./configure_openstack
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
#restart network
echo "Restart network"
echo "Waiting ..... "
sleep 3
/etc/init.d/networking restart
export SERVICE_ENDPOINT="http://$HOST_IP:35357/v2.0"
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl net.ipv4.ip_forward=1
sysctl -p
SERVICE_TENANT_NAME=${SERVICE_TENANT_NAME:-service}

#import configure interface in mysql
mysql -u root -p$dbpass -h$IP_MYSQL openstack << EOF
INSERT INTO configure_openstack (configure) VALUES
('export SERVICE_ENDPOINT=$SERVICE_ENDPOINT'),
('export HOST_IP=$HOST_IP'),
('export EXT_CONTROLL_IP=$EXT_HOST_IP'),
('export SERVICE_TENANT_NAME=$SERVICE_TENANT_NAME');
EOF


#Update OS
apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade

#import ppa openstack
echo "Import PPA OpenStack"
sleep 3
apt-get -y install python-software-properties
add-apt-repository cloud-archive:havana<<eof



eof

apt-get -y update && apt-get -y dist-upgrade
clear

#install messaging server
echo "Install Rabit messaging"
sleep 2
apt-get -y install rabbitmq-server
rabbitmqctl change_password guest $RABBIT_PASS
clear

echo "Install Rabit Messaging Success"
sleep 3

#install keystone
echo "Install Keystone"
sleep 3
apt-get -y install keystone
sed -e "s/^#*connection *=*.*/connection = mysql:\/\/keystone:$dbp_keystone@$IP_MYSQL\/keystone/" /etc/keystone/keystone.conf
rm -rf rm /var/lib/keystone/keystone.db
#sync db keystone
echo "Restart Keystone"
/etc/init.d/keystone restart
keystone-manage db_sync

et_id () {
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

#install glance

clear
echo "install glance"
sleep 3


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

#install nova
clear
echo "Install Nova server"
sleep 3

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
clear
echo "Install Neutron Controller"

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
echo "Restart Nova"
cd /etc/init.d/; for i in $( ls nova-* ); do service $i restart; cd; done

#install dashbroad
echo "Install dashbraod"
apt-get install memcached libapache2-mod-wsgi openstack-dashboard -y
apt-get remove --purge openstack-dashboard-ubuntu-theme -y
sleep 5
cd /etc/init.d/; for i in $( ls neutron-* ); do service $i restart; cd; done
echo "Install Success Full"
echo "De truy cap vao trang web quan tri ban ban co the vaot heo duong link sau:"
echo "Web manager: http://$HOST_IP/horizon"
echo "Username: admin 	password: $ADMIN_PASSWORD"