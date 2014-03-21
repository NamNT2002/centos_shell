#!/bin/bash
#Script Install OpenStack On Centos.
if [ "$1" != "--help" ]; then
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
	ovs-vsctl add-br br-int
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex $exten
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
auto $inter
iface $inter inet static
   address $CM_HOST_IP
   netmask $SUB_HOST
#
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

fi
