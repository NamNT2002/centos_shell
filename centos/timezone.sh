#!/bin/bash
#Change TimeZone
rm -f /etc/localtime
cd /usr/share/zoneinfo
list1=`ls`
checkntp=`rpm -qa | grep ntp-`
if [ "checkntp" = "" ]; then
	yum -y install ntp
fi
PS3="Chon TimeZone:"
echo "Choose from the list below."
select name in $list1
do
        break
done
if [ "$name" = "" ]; then
        echo "Error in entry."
        exit 1
fi
cd /usr/share/zoneinfo
checkname=`ls -d */ | sed 's/\///' | grep $name`
if [ "$name" = "$checkname" ]; then
cd /usr/share/zoneinfo/$name
listtime=`ls`
PS3="Chon TimeZone $name:"
select name1 in $listtime
do
	break
done
if [ "$name1" = "" ]; then
echo "Error in emtry"
exit 1
fi
name=$name/$name1
fi
ln -s /usr/share/zoneinfo/$name /etc/localtime
ntpdate pool.ntp.org
echo "You chose $name."



