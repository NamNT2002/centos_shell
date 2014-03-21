#!/bin/bash
#Script Install Networking services on a dedicated network node
. ./configure_openstack
#confiugre neutron
mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bk
cat > /etc/neutron/neutron.conf <<eof
[DEFAULT]
state_path = /var/lib/neutron
lock_path = $state_path/lock
core_plugin = neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2
notification_driver = neutron.openstack.common.notifier.rpc_notifier
auth_strategy = keystone
rabbit_host = $HOST_IP
rabbit_userid = guest
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
#signing_dir = $state_path/keystone-signing
[database]
connection = mysql://neutron:$dbp_neutron@$HOST_IP/neutron
[service_providers]
service_provider=LOADBALANCER:Haproxy:neutron.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default

eof

# configure /etc/neutron/api-paste.ini
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
auth_host = $HOST_IP
auth_uri = http://$HOST_IP:5000
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

#configure /etc/neutron/l3_agent.ini
mv /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.bk
cat > /etc/neutron/l3_agent.ini << eof
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True
eof

#configure /etc/neutron/dhcp_agent.ini
mv /etc/neutron/dhcp_agent.ini/etc/neutron/dhcp_agent.ini.bk
cat > /etc/neutron/dhcp_agent.ini << eof
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
eof

#configure /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini
mv /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini.bk
cat > /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini << eof
[ovs]
tenant_network_type = gre
enable_tunneling = True
tunnel_id_ranges = 1:1000
integration_bridge = br-int
tunnel_bridge = br-tun
local_ip = $CM_HOST_IP
[agent]
[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
[DATABASE]
sql_connection=mysql://neutron:$dbp_neutron@$HOST_IP/neutron
eof

#configure /etc/neutron/metadata_agent.ini
mv /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.bk
cat > /etc/neutron/metadata_agent.ini << eof
[DEFAULT]
auth_url = http://$HOST_IP:5000/v2.0
auth_region = regionOne
admin_tenant_name = service
admin_user = neutron
admin_password = $SERVICE_PASSWORD
nova_metadata_ip = $HOST_IP
metadata_proxy_shared_secret = $METADATA_PASS
eof
#restart nova api

cd /etc/init.d/; for i in $( ls neutron-* ); do sudo service $i restart; cd /root/; done
service dnsmasq restart
cd /etc/init.d/; for i in $( ls neutron-* ); do sudo service $i status; cd /root/; done
service dnsmasq status