#!/bin/bash
#Script Install OpenStack On Centos.
if [ "$1" != "--help" ]; then

	inter="eth0"
	#echo "Ten Cong Internal:"
	read -p "Ten Cong Internal:" inter
	if [ "$inter" = "" ]; then
		inter="eth0"
	fi
	exten="eth1"
	#echo "Ten Cong External:"
	read -p "Ten Cong External:" exten
	if [ "$exten" = "" ]; then
		exten="eth1"
	fi
HOST_IP=`ifconfig $inter | grep inet | awk '{print $2}' | sed 's/addr://'`
EXT_HOST_IP=`ifconfig $exten | grep inet | awk '{print $2}' | sed 's/addr://'`
DF_GATEWAY=`route -n | grep 'UG[ \t]' | awk '{print $2}'`
idf=`route -n | grep 'UG[ \t]' | awk '{print $8}'`
echo "Internal IP ADDR:"$HOST_IP
echo "External IP ADDR:"$EXT_HOST_IP
echo "Default Gateway: Interface " $idf " Ip Address:" $DF_GATEWAY
#echo "
#exit $?
fi