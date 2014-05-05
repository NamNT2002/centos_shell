#/bin/bash
#Install Controller

#configure basic
read -p"Ip address MySQL Server:" IP_MYSQL
echo
read -p"Password User Root MySQL:" DBP
echo
apt-get update && apt-get -y upgrade && apt-get dist-upgrade
apt-get -y install mysql-client
echo "select configure from configure_openstack" | mysql -u root -p$DBP -h$IP_MYSQL openstack > ~/list.txt && sed -n '1!p' ~/list.txt > ~/configure_openstack && chmod +x ~/configure_openstack && rm -rf ~/list.txt
clear
. ./configure_openstack

route -n | grep 'U[ \t]' | awk '{print $8;}' > ~/list_allinterface.txt

for interface in $( cat ~/list_allinterface.txt );
do ipadd=`/sbin/ifconfig $interface | grep inet | awk '{print $2}' | sed 's/addr://'`
netmask=`route -n | grep $interface | grep 'U[ \t]' | awk '{print $3}'`
echo "interface $interface  -  Dia Chi IP: $ipadd  -  Subnet Mask: $netmask ";
done
DF_GATEWAY=`route -n | grep 'UG[ \t]' | awk '{print $2, $8}'`
echo "Default gateway $DF_GATEWAY" 
rm -rf ~/list_allinterface.txt

#Configure Interface
	inter="eth0"
	#echo "Ten Cong Internal:"
	read -p "Ten Cong Internal:" inter
	if [ "$inter" = "" ]; then
	echo "Interface not none"
		read -p "Ten Cong Internal:" inter
	fi
	read -p "IP Address Internal:" HOST_IP
	if [ "$HOST_IP" = "" ]; then
		echo "IP address not none"
		read -p "IP Address Internal:" HOST_IP
	fi
	read -p "Subnet Internal:" SUB_HOST
	if [ "$SUB_HOST" = "" ]; then
		echo "Subnet mask Sai Cu Phap"
		read -p "Subnet Internal:" SUB_HOST
	fi
	echo ""
	echo ""
	exten="eth1"
	#echo "Ten Cong External:"
	read -p "Ten Cong External:" exten
	if [ "$exten" = "" ]; then
		echo "interface not none"
		read -p "Ten Cong External:" exten
	fi
	read -p "IP Address External:" EXT_HOST_IP
	if [ "$EXT_HOST_IP" = "" ]; then
		echo "IP address not none"
		read -p "IP Address External:" EXT_HOST_IP
	fi
	read -p "Subnet Mask External:" SUB_EXT
	if [ "$SUB_EXT" = "" ]; then
		echo "Subnet mask not none"
		read -p "Subnet Mask External:" SUB_EXT
		
	fi
	read -p "Default Gateway External:" DF_GATEWAY
	if [ "$DF_GATEWAY" = "" ]; then
		echo "Default Gateway not none"
		read -p "Default Gateway External:" DF_GATEWAY
	fi
	
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

#restart network
echo "Restart network"
echo "Waiting ..... "
sleep 3
/etc/init.d/networking restart
export SERVICE_ENDPOINT="http://$HOST_IP:35357/v2.0"

#export configure with database
mysql -u root -p$dbpass -h$IP_MYSQL openstack << EOF
INSERT INTO configure_openstack (configure) VALUES
('export SERVICE_ENDPOINT=$SERVICE_ENDPOINT'),
('export INT_CONTROLL_IP=$HOST_IP'),
('export EXT_CONTROLL_IP=$EXT_HOST_IP');
EOF