#!/bin/bash
#Show configure all interface
clear
all_int=`ip link show | grep BROADCAST | awk '{print $2;}' | sed 's/://'`
echo "======================================================================="
for interface in $all_int;
do ipadd=`/sbin/ifconfig $interface | grep inet | awk '{print $2}' | sed 's/addr://'`
netmask=`ifconfig $interface | grep Mask | awk '{print $4;}' | sed 's/Mask://'`
mac_int=`ip link show $interface | grep link/ether | awk '{print $2;}'`
trang_thai=`ip link show $interface | grep $interface | awk '{print $9;}'`
echo "interface $interface"
echo "Dia Chi IP: $ipadd  -  Subnet Mask: $netmask "
echo "$interface MAC ADDRESS: $mac_int - Status: $trang_thai"
echo "=======================================================================";
done
DF_GATEWAY=`route -n | grep 'UG[ \t]' | awk '{print $2, $8}'`
echo "Default gateway $DF_GATEWAY" 
echo ""
