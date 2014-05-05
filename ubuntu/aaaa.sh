all_interface=`/sbin/ifconfig eth0 |grep -B1 "inet addr" |awk '{ if ( $1 == "inet" ) { print $2 } else if ( $2 == "Link" ) { printf "%s:" ,$1 } }' |awk -F: '{ print $1 ": " $3 }' | sed '/^\lo/d'`
/sbin/ifconfig |grep -B1 "inet addr" |awk '{ if ( $1 == "inet" ) { print $2 } else if ( $2 == "Link" ) { printf "%s:" ,$1 } }' |awk -F: '{ print $1 ": " $3 }' | sed '/^\lo/d' >> list_allinterface.txt


route -n | grep 'U[ \t]' | awk '{print $8;}' >> list_allinterface.txt
list_interface=${all_interface%% *}


all_interface=`cat list_allinterface.txt



ifconfig eth0 | grep inet | awk '{print $2}' | sed 's/addr://'


route -n | grep 'U[ \t]' 