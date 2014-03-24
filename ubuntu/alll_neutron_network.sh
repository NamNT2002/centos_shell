#!/bin/bash
#Script Install OpenStack On Centos.
. ./configure_openstack
/sbin/ifconfig |grep -B1 "inet addr" |awk '{ if ( $1 == "inet" ) { print $2 } else if ( $2 == "Link" ) { printf "%s:" ,$1 } }' |awk -F: '{ print $1 ": " $3 }' | sed '/^\lo/d' >> allip.txt
#CM_HOST_IP=`ifconfig $inter | grep inet | awk '{print $2}' | sed 's/addr://'`
#CM_EXT_CM_HOST_IP=`ifconfig $exten | grep inet | awk '{print $2}' | sed 's/addr://'`
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
echo "Add app openstack and basic configure"
cat allip.txt
rm -rf allip.txt

	#configure  internal network
	inter="eth0"
	#echo "Ten Cong Internal:"
	read -p "Ten Cong Internal:" inter
	if [ "$inter" = "" ]; then
		inter="eth0"
	fi
	read -p "IP Address Internal:" CM_HOST_IP
	if [ "$CM_HOST_IP" = "" ]; then
		echo "IP Address Sai Cu Phap"
	fi
	read -p "Subnet Internal:" SUB_HOST
	if [ "$SUB_HOST" = "" ]; then
		echo "Subnet Mask Sai Cu Phap"
	fi
	echo ""
	echo ""
	#configure inter tunnel connect to computer node
	read -p "Ten Cong Tunner:" int
	if [ "$int" = "" ]; then
		int="eth2"
	fi
	read -p "IP Address Tunner:" NK_INT_IP
	if [ "$NK_INT_IP" = "" ]; then
		echo "IP Address Sai Cu Phap"
	fi
	read -p "Subnet Tunner:" SUB_INT
	if [ "$SUB_INT" = "" ]; then
		echo "Subnet Mask Sai Cu Phap"
	fi
	
	#configure exten network
	echo ""
	echo ""
	exten="eth1"
	#echo "Ten Cong External:"
	read -p "Ten Cong External:" exten
	if [ "$exten" = "" ]; then
		exten="eth1"
	fi
	read -p "IP Address External:" CM_EXT_CM_HOST_IP
	if [ "$CM_EXT_CM_HOST_IP" = "" ]; then
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
apt-get -y update
#install python mysql client
apt-get install python-mysqldb -y

#import ppa openstack
apt-get install python-software-properties -y
add-apt-repository cloud-archive:havana << eof



eof

apt-get update && apt-get dist-upgrade -y


#configure Kernel
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.default.rp_filter=1/net.ipv4.conf.default.rp_filter=0/' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.all.rp_filter=1/net.ipv4.conf.all.rp_filter=0/' /etc/sysctl.conf
sysctl net.ipv4.ip_forward=1
sysctl net.ipv4.conf.all.rp_filter=0
sysctl net.ipv4.conf.default.rp_filter=0
sysctl -p
/etc/init.d/networking restart
#install packet
apt-get -y install neutron-server neutron-dhcp-agent neutron-plugin-openvswitch-agent neutron-l3-agent openvswitch-controller openvswitch-switch openvswitch-datapath-dkms

	ovs-vsctl add-br br-int
	ovs-vsctl add-br br-ex
	ovs-vsctl add-port br-ex $exten
	ovs-vsctl add-port br-int $int
clear
#echo "Default Gateway: Interface " $idf " Ip Address:" $DF_GATEWAY
#echo "subnet: " $SUB_HOST
#echo "SuB EXT: " $SUB_EXT
InterfaceFile=/etc/network/interfaces
cat > $InterfaceFile <<EOF
# Localhost
auto lo
iface lo inet loopback
# Not Internet connected (OpenStack management network)
#configure network inte
auto $inter
iface $inter inet static
   address $CM_HOST_IP
   netmask $SUB_HOST
#
#configure network tunnel connect computer node
auto $int
iface $int inet static
   address $NK_INT_IP
   netmask $SUB_INT
#
#configure network exten
auto $exten
iface $exten inet manual
up ifconfig \$IFACE 0.0.0.0 up
up ip link set \$IFACE promisc on
down ip link set \$IFACE promisc off
down ifconfig \$IFACE down
auto br-ex
iface br-ex inet static
   address $CM_EXT_CM_HOST_IP
   netmask $SUB_EXT
   gateway $DF_GATEWAY
   dns-nameservers 8.8.8.8
EOF
echo "Restart network"
echo "Waiting ..... "
sleep 3
/etc/init.d/networking restart
clear
echo "Change Configure Interface Success Full"
echo "Internal interface $inter" IP ADDR:$CM_HOST_IP " - Subnet Mask:" $SUB_HOST
echo "External interface $exten" IP ADDR:$CM_EXT_CM_HOST_IP " - Subnet Mask:" $SUB_EXT " - Default Gateway:" $DF_GATEWAY
#echo "CM_HOST_IP=`ifconfig eth1 | grep inet | awk '{print $2}' | sed 's/addr://'`" >> /root/config_openstack
#echo "CM_EXT_CM_HOST_IP=`ifconfig eth0 | grep inet | awk '{print $2}' | sed 's/addr://'`" >> /root/config_openstack
#chmod +x /root/config_openstack
#rm -rf configure_openstack
echo "CM_HOST_IP=$CM_HOST_IP" >> configure_openstack
echo "CM_EXT_CM_HOST_IP=$CM_EXT_CM_HOST_IP" >> configure_openstack
chmod +x configure_openstack
/etc/init.d/networking restart


#config neutron
#!/bin/bash
#script configure neutron on controller
. ./configure_openstack
apt-get -y install neutron-server neutron-plugin-openvswitch
#METADATA_PASS=`openssl rand -hex 16`
#echo "METADATA_PASS=$METADATA_PASS" >> source_openstack

#configure /etc/nova/nova.conf
#[DEFAULT]
#neutron_metadata_proxy_shared_secret = $METADATA_PASS
#service_neutron_metadata_proxy = true

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
lock_path = $state_path/lock
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
ip addr flush $int
ip addr add $NK_INT_IP/24 dev br-int

cat > ~/restart_network.sh << eof
#!/bin/bash
#Scrip restart neutron network on boot
cd /etc/init.d/; for i in \$( ls neutron-* ); do service \$i restart; cd; done
ip addr flush $int
ip addr add $NK_INT_IP/24 dev br-int
eof

chmod +x ~/restart_network.sh
cat > /var/spool/cron/crontabs/root << eof
@reboot sh ~/restart_network.sh
eof

chmod 600 /var/spool/cron/crontabs/root
echo "Restart neutron"
cd /etc/init.d/; for i in $( ls neutron-* ); do service $i restart; cd; done
echo "Success Full"