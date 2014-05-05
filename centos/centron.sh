#!/bin/bash
read -p"Password Root MySQL: " -s dbpass
echo ""
wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
wget http://apt.sw.be/RPM-GPG-KEY.dag.txt
rpm --import RPM-GPG-KEY.dag.txt
rpm -Uvh rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
yum -y update && yum -y upgrade
yum -y install httpd \
gd fontconfig-devel libjpeg-devel libpng-devel gd-devel perl-GD \
openssl-devel perl-DBD-MySQL mysql-server mysql-devel \
php php-mysql php-gd \
php-ldap php-xml php-mbstring \
perl-DBI perl-DBD-MySQL \
perl-Config-IniFiles \
rrdtool perl-rrdtool \
perl-Crypt-DES perl-Digest-SHA1 perl-Digest-HMAC net-snmp-utils \
perl-Socket6 perl-IO-Socket-INET6 net-snmp net-snmp-libs php-snmp dmidecode lm_sensors perl-Net-SNMP net-snmp-perl \
fping cpp gcc gcc-c++ libstdc++ glib2-devel \
php-pear \

pear channel-update pear.php.net
pear upgrade-all

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
/etc/init.d/iptables stop
chkconfig iptables off
chkconfig httpd on
chkconfig mysqld on
/etc/init.d/httpd start
/etc/init.d/mysqld start
/etc/init.d/snmpd restart
chkconfig snmpd on
mysql -u root << EOF
GRANT USAGE ON *.* TO root@'%' IDENTIFIED BY '$dbpass';
UPDATE mysql.user SET Password=PASSWORD('$dbpass') WHERE User='root';
delete from mysql.user where user=''; 
GRANT ALL PRIVILEGES ON * . * TO  'root'@'%' WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;
EOF
/etc/init.d/mysqld restart
clear

#configure nagios
wget http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-4.0.4.tar.gz
wget http://nagios-plugins.org/download/nagios-plugins-2.0.tar.gz
userdel nagios 
useradd nagios
groupadd nagcmd
usermod -a -G nagcmd nagios

tar -xvf nagios-4.0.4.tar.gz
tar -xvf nagios-plugins-2.0.tar.gz

cd nagios-4.0.4 
./configure --with-command-group=nagcmd

clear
echo "Make all ...."
sleep 3
make all

clear
echo "Make install ..."
sleep 3
make install

clear
echo "make install-init"
sleep 3
make install-init

clear
echo "make install-config"
sleep 3
make install-config

clear
echo "make install-commandmode"
sleep 3
make install-commandmode

clear
echo "make install-webcon"
sleep 3
make install-webcon

cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/
chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
/etc/init.d/nagios start
/etc/init.d/httpd restart

#confiugre nagius pass
#htpasswd –c /usr/local/nagios/etc/htpasswd.users nagiosadmin
#htpasswd -c /usr/local/nagios/etc/htpasswd.users admin
# htpasswd -m /usr/local/nagios/etc/htpasswd.users namnt

#install nagios plugin
cd nagios-plugins-2.0
./configure --with-nagios-user=nagios --with-nagios-group=nagios

clear
echo "make"
sleep 3
make

clear
echo "make install"
sleep 3
make install

clear
chkconfig --add nagios
chkconfig --level 35 nagios on

#install subversion
yum -y remove subversion

wget http://opensource.wandisco.com/centos/6/svn-1.8/RPMS/x86_64/serf-1.3.4-1.x86_64.rpm
wget http://opensource.wandisco.com/centos/6/svn-1.8/RPMS/x86_64/subversion-1.8.8-1.x86_64.rpm
wget http://opensource.wandisco.com/centos/6/svn-1.8/RPMS/x86_64/subversion-tools-1.8.8-1.x86_64.rpm

yum -y install serf-1.3.4-1.x86_64.rpm
yum -y install subversion-1.8.8-1.x86_64.rpm
yum -y install subversion-tools-1.8.8-1.x86_64.rpm

#install ndoutils-2.0.0.tar.gz
wget http://jaist.dl.sourceforge.net/project/nagios/ndoutils-2.x/ndoutils-2.0.0/ndoutils-2.0.0.tar.gz
tar -xvf ndoutils-2.0.0.tar.gz
cd ndoutils-2.0.0
./configure --prefix=/usr/local/nagios/ --enable-mysql --disable-pgsql \
--with-ndo2db-user=nagios --with-ndo2db-group=nagios
make

cp ./src/ndomod-4x.o /usr/local/nagios/bin/ndomod.o
cp ./src/ndo2db-4x /usr/local/nagios/bin/ndo2db
cp ./config/ndo2db.cfg-sample /usr/local/nagios/etc/ndo2db.cfg
cp ./config/ndomod.cfg-sample /usr/local/nagios/etc/ndomod.cfg
chmod 774 /usr/local/nagios/bin/ndo*
chown nagios:nagios /usr/local/nagios/bin/ndo*

cp ./daemon-init /etc/init.d/ndo2db
chmod +x /etc/init.d/ndo2db

chkconfig --add ndo2db

#install centreon
wget http://download.centreon.com/centreon/centreon-2.5.0.tar.gz
tar -xvf centreon-2.5.0.tar.gz
cd centreon-2.5.0/
export PATH="$PATH:/usr/local/nagios/bin/"
mkdir -p /var/log/monitor/
mkdir -p /usr/lib/nagios/plugins
mkdir -p /etc/centreon/configuration
mv /root/nagios-plugins-2.0/plugins /usr/lib/nagios/plugins
mkdir -p /etc/centreon/module
touch /etc/centreon/daemon
cd ~/centreon-2.5.0
./install.sh -i << eof
y
y
y
y

y

y

y

y

y

y
/usr/share/pear/PEAR.php

y

y
centreon

/var/log/monitor/



centreon
/etc/init.d
/etc/centreon
/etc/centreon/configuration
/etc/centreon/module
/etc/centreon/daemon
y
y
y
y

y


y
y

y
y

y


y
y
eof

service httpd reload