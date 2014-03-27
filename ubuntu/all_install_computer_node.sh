#!/bin/bash
#scrip all install computer node

#!/bin/bash
#Script Install OpenStack On Centos.

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
rm -rf allip.txt
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
   address $CM_HOST_IP
   netmask $SUB_HOST
#
#configre network connect to network controll
#configure network tunnel connect computer node
auto $int
iface $int inet static
   address $NK_INT_IP
   netmask $SUB_INT
#configure network exten
auto $exten
iface $exten inet static
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

echo "Add app openstack and basic configure"
apt-get -y update
#install python mysql client
apt-get install python-mysqldb -y

#import ppa openstack
apt-get install python-software-properties -y
add-apt-repository cloud-archive:havana << eof



eof

apt-get update && apt-get dist-upgrade -y




#nova
#!/bin/bash
#Install Computer Node
#install nova-compute-kvm
. ./configure_openstack
apt-get -y install nova-compute-kvm python-guestfs
dpkg-statoverride  --update --add root root 0644 /boot/vmlinuz-$(uname -r)
#wget https://raw.githubusercontent.com/NamNT2002/centos_shell/master/ubuntu/statoverride
#mv statoverride /etc/kernel/postinst.d/statoverride
cat > /etc/kernel/postinst.d/statoverride << eof
#!/bin/sh
version="\$1"
# passing the kernel version is required
[ -z "\${version}" ] && exit 0
dpkg-statoverride --update --add root root 0644 /boot/vmlinuz-\${version}
eof
chmod +x /etc/kernel/postinst.d/statoverride
mv /etc/nova/nova.conf /etc/nova/nova.conf.bk
cat > /etc/nova/nova.conf <<eof
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
auth_strategy=keystone
rpc_backend = nova.rpc.impl_kombu
rabbit_host = $HOST_IP
rabbit_password = $RABBIT_PASS
my_ip=$CM_HOST_IP
vnc_enabled=True
vncserver_listen=0.0.0.0
vncserver_proxyclient_address=$CM_HOST_IP
novncproxy_base_url=http://$HOST_IP:6080/vnc_auto.html
glance_host=$HOST_IP

resume_guests_state_on_host_boot=True

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
# The SQLAlchemy connection string used to connect to t
connection = mysql://nova:$dbp_nova@$HOST_IP/nova
eof

#configure api nova
mv /etc/nova/api-paste.ini /etc/nova/api-paste.ini.bk
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
rm -rf /var/lib/nova/nova.sqlite
/etc/init.d/nova-compute restart

#!/bin/bash
#Script configure neutron on computernode

#configure sysctl
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.default.rp_filter=1/net.ipv4.conf.default.rp_filter=0/' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.all.rp_filter=1/net.ipv4.conf.all.rp_filter=0/' /etc/sysctl.conf
sysctl net.ipv4.ip_forward=1
sysctl net.ipv4.conf.all.rp_filter=0
sysctl net.ipv4.conf.default.rp_filter=0
sysctl -p
/etc/init.d/networking restart

apt-get -y install neutron-plugin-openvswitch-agent openvswitch-datapath-dkms
/etc/init.d/openvswitch-switch restart
ovs-vsctl add-br br-int
ovs-vsctl add-port br-int $int

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
rabbit_password = $RABBIT_PASS
rabbit_port = 5672
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
auth_host = $HOST_IP
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
#integration_bridge = br-int
#tunnel_bridge = $inter
#local_ip = $CM_HOST_IP
network_vlan_ranges = physnet1
bridge_mappings = physnet1:br-int
[agent]
[securitygroup]
firewall_driver=neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
eof

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
#configure nova.conf
#network_api_class=nova.network.neutronv2.api.API
#neutron_url=http://controller:9696
#neutron_auth_strategy=keystone
#neutron_admin_tenant_name=service
#neutron_admin_username=neutron
#neutron_admin_password=NEUTRON_PASS
#neutron_admin_auth_url=http://controller:35357/v2.0
#linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
#firewall_driver=nova.virt.firewall.NoopFirewallDriver
#security_group_api=neutron

#configure restart nova computer
/etc/init.d/nova-compute restart
/etc/init.d/neutron-plugin-openvswitch-agent restart