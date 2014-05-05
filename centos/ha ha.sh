for i in $(cat /root/list3.txt); do 
echo $i >> /root/list3.txt
echo $i''{a..z} | tr " " "\n" >> /root/list3.txt
echo $i''{A..Z} | tr " " "\n" >> /root/list3.txt
echo $i''{0..1} | tr " " "\n" >> /root/list3.txt
echo $i''\! >> /root/list3.txt
echo $i''\@ >> /root/list3.txt
echo $i''\# >> /root/list3.txt
echo $i''\$ >> /root/list3.txt
echo $i''\% >> /root/list3.txt
echo $i''\^ >> /root/list3.txt
echo $i''\& >> /root/list3.txt
echo $i''\* >> /root/list3.txt
echo $i''\( >> /root/list3.txt
echo $i''\) >> /root/list3.txt
echo $i''\- >> /root/list3.txt
echo $i''\+ >> /root/list3.txt
echo $i''\. >> /root/list3.txt
echo $i''\: >> /root/list3.txt;
done
