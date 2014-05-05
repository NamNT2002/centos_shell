#!/bin/bash
#Install MariaDB on Centos
read -p "Database Password:" -s password
echo ""
#add repo
cat >  /etc/yum.repos.d/mariadb.repo << eof
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/5.5/centos5-x86
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
eof

#remove old mysql
yum -y remove mysql-* mysql*

#install MariaDB
yum -y install MariaDB-server MariaDB-client

#configure MariaDB
/etc/init.d/mysql restart
mysql_secure_installation << eof

Y
$password
$password
Y
Y
Y
Y
eof

mysql -u root -p$password <<eof
GRANT USAGE ON *.* TO root@'%' IDENTIFIED BY '$password';
UPDATE mysql.user SET Password=PASSWORD('$password') WHERE User='root';
delete from mysql.user where user=''; 
GRANT ALL PRIVILEGES ON * . * TO  'root'@'%' WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;

eof

/etc/init.d/mysql restart
/etc/init.d/iptables stop
chkconfig mysql on
chkconfig iptables off

clear
echo "Install MariaDB Success"
echo "Password Database: $password"