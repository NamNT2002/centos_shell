#/bin/bash
#Script show all user Linux
abc=`awk -F':' '{ print $1}' /etc/passwd`
array=($abc)
len=${#array[*]}
y=0
while [ $y -le $[len-1] ]; do
userid=`id -u ${array[$y]}`
groupid=`id -g ${array[$y]}`
        echo "$[y+1]) user: ${array[$y]} - user id: $userid - group id: $groupid"
        let y++
done	


