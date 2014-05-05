#!/bin/bash
#Install neutron Network
dir=`pwd`
rm -rf $dir/configure_openstack
InterfaceFile=/etc/network/interfaces
read -p"Ip address MySQL Server: " IP_MYSQL
read -p"Password User Root MySQL: " DBP
echo ""

#install mysql client
apt-get update && apt-get -y upgrade && apt-get dist-upgrade
apt-get -y install mysql-client python-mysqldb python-software-properties
add-apt-repository cloud-archive:havana << eof



eof
apt-get update && apt-get dist-upgrade -y

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.default.rp_filter=1/net.ipv4.conf.default.rp_filter=0/' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.all.rp_filter=1/net.ipv4.conf.all.rp_filter=0/' /etc/sysctl.conf
sysctl -p
/etc/init.d/networking restart
#install packet
apt-get -y install neutron-server neutron-dhcp-agent neutron-plugin-openvswitch-agent neutron-l3-agent openvswitch-controller openvswitch-switch openvswitch-datapath-dkms

echo "select configure from configure_openstack" | mysql -u root -p$DBP -h$IP_MYSQL openstack > $dir/list.txt && sed -n '1!p' $dir/list.txt > $dir/configure_openstack && chmod +x $dir/configure_openstack && rm -rf $dir/list.txt
clear

#list all ip address
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
echo ""

#configure interface
echo "Configure Interface Internal"
sh $dir/network/nw_int_int
sh $dir/network/nw_int_ip
sh $dir/network/nw_int_sub
echo ""

echo "Configure Interface Connect Computer Node"
sh $dir/network/nw_cm_int
sh $dir/network/nw_cm_ip
sh $dir/network/nw_cm_sub
echo ""

echo "Configure Interface External"
sh $dir/network/nw_ext_int
sh $dir/network/nw_ext_ip
sh $dir/network/nw_ext_sub
sh $dir/network/nw_df_gateway

. ./configure_openstack

ovs-vsctl add-br br-int
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex $nw_ext_int
ovs-vsctl add-port br-int $nw_cm_int
clear

cat > $InterfaceFile <<EOF
# Localhost
auto lo
iface lo inet loopback
# Not Internet connected (OpenStack management network)
#configure network tunnel connect computer node

auto $nw_cm_int
iface $nw_cm_int inet static
   address $nw_cm_ip
   netmask $nw_cm_sub
#
#configure network inte
auto $nw_int_int
iface $nw_int_int inet static
   address $nw_int_ip
   netmask $nw_int_sub
#
#configure network exten
auto $nw_ext_int
iface $nw_ext_int inet manual
up ifconfig \$IFACE 0.0.0.0 up
up ip link set \$IFACE promisc on
down ip link set \$IFACE promisc off
down ifconfig \$IFACE down
auto br-ex
iface br-ex inet static
   address $nw_ext_ip
   netmask $nw_ext_sub
   gateway $nw_df_gateway
   dns-nameservers 8.8.8.8
EOF
echo "Restart network"
echo "Waiting ..... "
sleep 3
/etc/init.d/networking restart
clear
. ./configure_openstack
mysql -u root -p$dbpass -h$IP_MYSQL openstack << EOF
INSERT INTO configure_openstack (configure) VALUES
('export nw_ext_ip=$nw_ext_ip'),
('export nw_int_ip=$nw_int_ip'),
('export nw_cm_ip=$nw_cm_ip');
EOF

apt-get -y install neutron-server neutron-plugin-openvswitch

#configure /etc/neutron/dhcp_agent.ini
mv /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.bk
cat > /etc/neutron/dhcp_agent.ini << eof
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
eof

#configure /etc/neutron/l3_agent.ini
mv /etc/neutron/l3_agent.ini > /etc/neutron/l3_agent.inibk
cat > /etc/neutron/l3_agent.ini << eof
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True
eof

#configure /etc/neutron/neutron.conf
mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bk
cat > /etc/neutron/neutron.conf << eof

[DEFAULT]
state_path = /var/lib/neutron
lock_path = \$state_path/lock
core_plugin = neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2
notification_driver = neutron.openstack.common.notifier.rpc_notifier
control_exchange = neutron
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
connection = mysql://neutron:$dbp_neutron@$IP_MYSQL/neutron
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
