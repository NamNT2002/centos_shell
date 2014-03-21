#!/bin/bash
#Script Install keystone Neutron

#import Configure
. ./configure_openstack
export SERVICE_TOKEN="ADMIN"
export SERVICE_ENDPOINT="http://$HOST_IP:35357/v2.0"
SERVICE_TENANT_NAME=${SERVICE_TENANT_NAME:-service}
get_id () {
    echo `$@ | awk '/ id / { print $4 }'`
}
keystone user-create --name neutron --pass "$SERVICE_PASSWORD" --email neutron@domain.com
keystone user-role-add --tenant service --user neutron --role admin
NEUTRON_SERVICE=$(get_id keystone service-create --name neutron --type network --description Networking)
keystone endpoint-create --region RegionOne --service-id $NEUTRON_SERVICE --publicurl 'http://'"$EXT_HOST_IP"':9696' --adminurl 'http://'"$HOST_IP"':9696' --internalurl 'http://'"$HOST_IP"':9696'

echo "Success Full"