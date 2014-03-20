#!/bin/bash
#Script Install Image Service
. ./configure_openstack
apt-get -y install glance python-glanceclient
clear
echo "Install Packet success ...."
echo "Waiting configure Glance"
sleep 5
mv /etc/glance/glance-api.conf /etc/glance/glance-api.conf.bk
mv /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.bk
mv /etc/glance/glance-registry-paste.ini /etc/glance/glance-registry-paste.ini.bk
mv /etc/glance/glance-api-paste.ini /etc/glance/glance-api-paste.ini.bk
echo "Setup glan-api.conf"
cat > /etc/glance/glance-api.conf <<eof
[DEFAULT]
default_store = file
bind_host = 0.0.0.0
bind_port = 9292
log_file = /var/log/glance/api.log
backlog = 4096
sql_connection = mysql://glance:$dbp_glance@$HOST_IP/glance
sql_idle_timeout = 3600
workers = 1
registry_host = 0.0.0.0
registry_port = 9191
registry_client_protocol = http
notifier_strategy = noop
rabbit_host = $HOST_IP
rabbit_port = 5672
rabbit_use_ssl = false
rabbit_userid = guest
rabbit_password = $RABBIT_PASS
rabbit_virtual_host = /
rabbit_notification_exchange = glance
rabbit_notification_topic = notifications
rabbit_durable_queues = False
qpid_notification_exchange = glance
qpid_notification_topic = notifications
qpid_hostname = localhost
qpid_port = 5672
qpid_username =
qpid_password =
qpid_sasl_mechanisms =
qpid_reconnect_timeout = 0
qpid_reconnect_limit = 0
qpid_reconnect_interval_min = 0
qpid_reconnect_interval_max = 0
qpid_reconnect_interval = 0
qpid_heartbeat = 5
qpid_protocol = tcp
qpid_tcp_nodelay = True
filesystem_store_datadir = /var/lib/glance/images/
swift_store_auth_version = 2
swift_store_auth_address = 127.0.0.1:5000/v2.0/
swift_store_user = jdoe:jdoe
swift_store_key = a86850deb2742ec3cb41518e26aa2d89
swift_store_container = glance
swift_store_create_container_on_put = False
swift_store_large_object_size = 5120
swift_store_large_object_chunk_size = 200
swift_enable_snet = False
s3_store_host = 127.0.0.1:8080/v1.0/
s3_store_access_key = <20-char AWS access key>
s3_store_secret_key = <40-char AWS secret key>
s3_store_bucket = <lowercased 20-char aws access key>glance
s3_store_create_bucket_on_put = False
rbd_store_ceph_conf = /etc/ceph/ceph.conf
rbd_store_user = glance
rbd_store_pool = images
rbd_store_chunk_size = 8
sheepdog_store_address = localhost
sheepdog_store_port = 7000
sheepdog_store_chunk_size = 64
delayed_delete = False
scrub_time = 43200
scrubber_datadir = /var/lib/glance/scrubber
image_cache_dir = /var/lib/glance/image-cache/
[keystone_authtoken]
auth_host = $HOST_IP
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = glance
admin_password = $SERVICE_PASSWORD
[paste_deploy]
flavor = keystone
eof

echo "Setup glance-registry.conf"
cat > /etc/glance/glance-registry.conf <<eof
[DEFAULT]
bind_host = 0.0.0.0
bind_port = 9191
log_file = /var/log/glance/registry.log
backlog = 4096
sql_connection = mysql://glance:$dbp_glance@$HOST_IP/glance
sql_idle_timeout = 3600
api_limit_max = 1000
limit_param_default = 25
[keystone_authtoken]
auth_host = $HOST_IP
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = glance
admin_password = $SERVICE_PASSWORD
[paste_deploy]
flavor = keystone
eof

echo "configure glance-registry-paste.ini"
cat > /etc/glance/glance-registry-paste.ini << eof
[pipeline:glance-registry]
pipeline = unauthenticated-context registryapp
[pipeline:glance-registry-keystone]
pipeline = authtoken context registryapp
[pipeline:glance-registry-trusted-auth]
pipeline = context registryapp
[app:registryapp]
paste.app_factory = glance.registry.api.v1:API.factory
[filter:context]
paste.filter_factory = glance.api.middleware.context:ContextMiddleware.factory
[filter:unauthenticated-context]
paste.filter_factory = glance.api.middleware.context:UnauthenticatedContextMiddleware.factory
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
admin_password = $SERVICE_PASSWORD
admin_user = glance
admin_tenant_name = service
auth_protocol = http
auth_port = 35357
auth_host = $HOST_IP
eof

echo "configure glance-api-paste.ini"
cat > /etc/glance/glance-api-paste.ini << eof
[pipeline:glance-api]
pipeline = versionnegotiation unauthenticated-context rootapp
[pipeline:glance-api-caching]
pipeline = versionnegotiation unauthenticated-context cache rootapp
[pipeline:glance-api-cachemanagement]
pipeline = versionnegotiation unauthenticated-context cache cachemanage rootapp
[pipeline:glance-api-keystone]
pipeline = versionnegotiation authtoken context rootapp
[pipeline:glance-api-keystone+caching]
pipeline = versionnegotiation authtoken context cache rootapp
[pipeline:glance-api-keystone+cachemanagement]
pipeline = versionnegotiation authtoken context cache cachemanage rootapp
[pipeline:glance-api-trusted-auth]
pipeline = versionnegotiation context rootapp
[pipeline:glance-api-trusted-auth+cachemanagement]
pipeline = versionnegotiation context cache cachemanage rootapp
[composite:rootapp]
paste.composite_factory = glance.api:root_app_factory
/: apiversions
/v1: apiv1app
/v2: apiv2app
[app:apiversions]
paste.app_factory = glance.api.versions:create_resource
[app:apiv1app]
paste.app_factory = glance.api.v1.router:API.factory
[app:apiv2app]
paste.app_factory = glance.api.v2.router:API.factory
[filter:versionnegotiation]
paste.filter_factory = glance.api.middleware.version_negotiation:VersionNegotiationFilter.factory
[filter:cache]
paste.filter_factory = glance.api.middleware.cache:CacheFilter.factory
[filter:cachemanage]
paste.filter_factory = glance.api.middleware.cache_manage:CacheManageFilter.factory
[filter:context]
paste.filter_factory = glance.api.middleware.context:ContextMiddleware.factory
[filter:unauthenticated-context]
paste.filter_factory = glance.api.middleware.context:UnauthenticatedContextMiddleware.factory
[filter:authtoken]
paste.filter_factory = keystoneclient.middleware.auth_token:filter_factory
admin_password = $SERVICE_PASSWORD
admin_user = glance
admin_tenant_name = service
auth_protocol = http
auth_port = 35357
auth_host = $HOST_IP
delay_auth_decision = true
[filter:gzip]
paste.filter_factory = glance.api.middleware.gzip:GzipMiddleware.factory
eof
rm -rf /var/lib/glance/glance.sqlite
/etc/init.d/glance-api restart && /etc/init.d/glance-registry restart
glance-manage db_sync
/etc/init.d/glance-api restart && /etc/init.d/glance-registry restart
echo "Install Glance Success Full"