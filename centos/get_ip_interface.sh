#!/bin/bash
route -n | grep 'U[ \t]' | awk '{print $8;}' > list_allinterface.txt

for interface in $( cat list_allinterface.txt );
do ipadd=`/sbin/ifconfig $interface | grep inet | awk '{print $2}' | sed 's/addr://'`
netmask=`route -n | grep $interface | grep 'U[ \t]' | awk '{print $3}'`
echo "interface $interface  -  Dia Chi IP: $ipadd  -  Subnet Mask: $netmask ";
done
DF_GATEWAY=`route -n | grep 'UG[ \t]' | awk '{print $2, $8}'`
echo "Default gateway $DF_GATEWAY" 