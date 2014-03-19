#!/bin/bash
#Script Install OpenStack On Centos.
if [ "$1" != "--help" ]; then
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
clear
echo "Change Configure Interface Success Full"
echo "Internal interface $inter" IP ADDR:$HOST_IP " - Subnet Mask:" $SUB_HOST
echo "External interface $exten" IP ADDR:$EXT_HOST_IP " - Subnet Mask:" $SUB_EXT " - Default Gateway:" $DF_GATEWAY
echo "export HOST_IP=`ifconfig $inter | grep inet | awk '{print $2}' | sed 's/addr://'`" >> config_openstack
echo "export EXT_HOST_IP=`ifconfig $exten | grep inet | awk '{print $2}' | sed 's/addr://'`" >> config_openstack
fi
