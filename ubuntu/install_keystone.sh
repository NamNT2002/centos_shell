#!/bin/bash
#Install Keystone
. ./configure_openstack

ADMIN_PASSWORD=`openssl rand -hex 16`
SERVICE_PASSWORD=`openssl rand -hex 16`
export SERVICE_TOKEN="ADMIN"
export SERVICE_ENDPOINT="http://$HOST_IP:35357/v2.0"
echo "export SERVICE_TOKEN=ADMIN" >> source_openstack
echo "export SERVICE_ENDPOINT=http://$HOST_IP:35357/v2.0" >> source_openstack
SERVICE_TENANT_NAME=${SERVICE_TENANT_NAME:-service}
echo "Import PPA OpenStack"
sleep 3
apt-get -y install python-software-properties
add-apt-repository cloud-archive:havana<<eof



eof
apt-get -y update && apt-get -y dist-upgrade
clear
echo "Install Rabit messaging"
sleep 2
RABBIT_PASS=`openssl rand -hex 16`
echo RABBIT_PASS=$RABBIT_PASS >> configure_openstack
echo ADMIN_PASSWORD=$ADMIN_PASSWORD >> configure_openstack
echo SERVICE_PASSWORD=$SERVICE_PASSWORD >> configure_openstack
echo SERVICE_TOKEN=$SERVICE_TOKEN >> configure_openstack
echo SERVICE_ENDPOINT=$SERVICE_ENDPOINT >> configure_openstack
apt-get -y install rabbitmq-server
rabbitmqctl change_password guest $RABBIT_PASS
clear
echo "Install Rabit Messaging Success"
echo "Install Keystone"
apt-get -y install keystone
#sed -i 's|connection = sqlite:////var/lib/keystone/keystone.db|connection = mysql://keystone:[$dbp_keystone]@[$HOST_IP]/keystone |g' /etc/keystone/keystone.conf
sed '/^\connection = sqlite/d' /etc/keystone/keystone.conf >> keystoneconf
mv /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bk
sed '/^\[sql]/d' keystoneconf >> keystoneconf1
rm -rf keystoneconf
sed '/^\#/d' keystoneconf1 >> /etc/keystone/keystone.conf
rm -rf keystoneconf1
echo "[sql]" >> /etc/keystone/keystone.conf
echo "connection = mysql://keystone:$dbp_keystone@$HOST_IP/keystone" >> /etc/keystone/keystone.conf
rm -rf rm /var/lib/keystone/keystone.db
#sync db keystone
echo "Restart Keystone"
/etc/init.d/keystone restart
keystone-manage db_sync

get_id () {
    echo `$@ | awk '/ id / { print $4 }'`
}
# Tenants
keystone tenant-create --name admin
keystone tenant-create --name service

# Users
keystone user-create --name admin --pass "$ADMIN_PASSWORD" --email admin@domain.com

# Roles
keystone role-create --name Member
keystone role-create --name admin
keystone role-create --name KeystoneAdmin
keystone role-create --name KeystoneServiceAdmin
keystone role-create --name ResellerAdmin

# Users
keystone user-create --name nova --pass "$SERVICE_PASSWORD" --email nova@domain.com
keystone user-create --name glance --pass "$SERVICE_PASSWORD" --email glance@domain.com
#keystone user-create --name neutron --pass "$SERVICE_PASSWORD" --email neutron@domain.com
keystone user-create --name cinder --pass "$SERVICE_PASSWORD" --email cinder@domain.com
keystone user-create --name swift --pass "$SERVICE_PASSWORD" --email swift@domain.com
keystone user-create --name ceilometer --pass "$SERVICE_PASSWORD" --email ceilometer@domain.com
keystone user-create --name heat --pass "$SERVICE_PASSWORD" --email heat@domain.com

# Roles
keystone user-role-add --tenant admin --user admin --role admin 
keystone user-role-add --tenant admin --user admin --role KeystoneAdmin
keystone user-role-add --tenant admin --user admin --role KeystoneServiceAdmin

keystone user-role-add --tenant service --user nova --role admin
keystone user-role-add --tenant service --user glance --role admin
#keystone user-role-add --tenant service --user neutron --role admin
keystone user-role-add --tenant service --user cinder --role admin
keystone user-role-add --tenant service --user swift --role admin
keystone user-role-add --tenant service --user ceilometer --role admin
keystone user-role-add --tenant service --user ceilometer --role ResellerAdmin
keystone user-role-add --tenant service --user heat --role admin

# Services
NOVA_SERVICE=$(get_id keystone service-create --name nova --type compute --description Compute)
CINDER_SERVICE=$(get_id keystone service-create --name cinder --type volume --description Volume)
GLANCE_SERVICE=$(get_id keystone service-create --name glance --type image --description Image)
KEYSTONE_SERVICE=$(get_id keystone service-create --name keystone --type identity --description Identity)
EC2_SERVICE=$(get_id keystone service-create --name ec2 --type ec2 --description EC2)
#NEUTRON_SERVICE=$(get_id keystone service-create --name neutron --type network --description Networking)
SWIFT_SERVICE=$(get_id keystone service-create --name swift --type object-store --description Storage)
CEILOMETER_SERVICE=$(get_id keystone service-create --name ceilometer --type metering --description Metering)
HEAT_SERVICE=$(get_id keystone service-create --name heat --type orchestration --description Orchestration)
CFN_SERVICE=$(get_id keystone service-create --name heat-cfn --type cloudformation --description Cloudformation)

# Service endpoints
keystone endpoint-create --region RegionOne --service-id $NOVA_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8774/v2/$(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8774/v2/$(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8774/v2/$(tenant_id)s'
keystone endpoint-create --region RegionOne --service-id $CINDER_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8776/v1/$(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8776/v1/$(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8776/v1/$(tenant_id)s'
keystone endpoint-create --region RegionOne --service-id $GLANCE_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':9292/v2' --adminurl 'http://'"$HOST_IP"':9292/v2' --internalurl 'http://'"$HOST_IP"':9292/v2'
keystone endpoint-create --region RegionOne --service-id $KEYSTONE_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':5000/v2.0' --adminurl 'http://'"$HOST_IP"':35357/v2.0' --internalurl 'http://'"$HOST_IP"':5000/v2.0'
keystone endpoint-create --region RegionOne --service-id $EC2_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8773/services/Cloud' --adminurl 'http://'"$HOST_IP"':8773/services/Admin' --internalurl 'http://'"$HOST_IP"':8773/services/Cloud'
#keystone endpoint-create --region RegionOne --service-id $NEUTRON_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':9696' --adminurl 'http://'"$HOST_IP"':9696' --internalurl 'http://'"$HOST_IP"':9696'
keystone endpoint-create --region RegionOne --service-id $SWIFT_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8080/v1/AUTH_%(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8080' --internalurl 'http://'"$HOST_IP"':8080/v1/AUTH_%(tenant_id)s'
keystone endpoint-create --region RegionOne --service-id $CEILOMETER_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8777' --adminurl 'http://'"$HOST_IP"':8777' --internalurl 'http://'"$HOST_IP"':8777'
keystone endpoint-create --region RegionOne --service-id $HEAT_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8004/v1/$(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8004/v1/$(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8004/v1/$(tenant_id)s'
keystone endpoint-create --region RegionOne --service-id $CFN_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':8000/v1' --adminurl 'http://'"$HOST_IP"':8000/v1' --internalurl 'http://'"$HOST_IP"':8000/v1'

echo "Install Success Full"
#echo `keystone endpoint-list`