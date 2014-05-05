abc=`cat /proc/cpuinfo | grep processor`
abc=${abc##* }
abc=$[abc+1]

cat /proc/cpuinfo | grep 'model name' | awk '{print $4 " " $5 " " $6 " " $7 " " $9;}' > ~/namechip.txt
namechip=`head -1 ~/namechip.txt`
echo $namechip