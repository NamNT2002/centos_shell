#!/bin/bash
#Configrue network interface

#list All interface And MAC Address
all_int=`ip link show | grep BROADCAST | awk '{print $2;}' | sed 's/://'`
for i in $all_int; do
mac_int=`ip link show $i | grep link/ether | awk '{print $2;}'`
echo "interface: $i - MAC Address: $mac_int";
done
