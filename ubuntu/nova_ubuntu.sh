#!/bin/bash
#Install Compute controller services
. ./configure_openstack
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