#!/bin/bash
#script configure neutron on controller
. ./configure_openstack
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
tenant_network_type = gre
tunnel_id_ranges = 1:1000
enable_tunneling = True
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