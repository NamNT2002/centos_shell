#show database mysql
echo "select chuoi from test" | mysql -u root -pNguyenthenam2501@ -h172.16.6.23 namnt > ~/list.txt && sed -n '1!p' ~/list.txt > list1.txt

#so sanh
-lt (<)

-gt (>)

-le (<=)

-ge (>=)

-eq (==)

-ne (!=)

#vong lap for
 for i in $( cat abc.txt | tr " " "\n" ); do echo "doi nay dep lam $i oi" >> testfile.txt; done
 
 vong lap while do
 cat testfile.txt | while read fn; do
> echo "hay hay $fn"

n=1
while [ $n -le 20 ]; do echo $n; let n++; done


y=1
while [ $y -le 12 ]; do
        x=1
        while [ $x -le 12 ]; do
                printf "| % 5d " $(( $x * $y ))
                let x++
        done
        echo ""
        let y++
done

#select
PS3="Choose (1-5):"
echo "Choose from the list below."
select name in red green blue yellow magenta
do
        break
done
if [ "$name" = "" ]; then
        echo "Error in entry."
        exit 1
fi
echo "You chose $name."

# Mang array
array=(red green blue yellow magenta)
len=${#array[*]}
echo "The array has $len members. They are:"
i=0
while [ $i -lt $len ]; do
        echo "$[i+1]: ${array[$i]}"
        let i++
done


Operator "#" means "delete from the left, to the first case of what follows."

$ x="This is my test string."
$ echo ${x#* }

is my test string.

                    
                    
Operator "##" means "delete from the left, to the last case of what follows."

$ x="This is my test string."
$ echo ${x##* }

string.

Operator "%" means "delete from the right, to the first case of what follows."

$ x="This is my test string."
$ echo ${x% *}

This is my test

                        
                    
Operator "%%" means "delete from the right, to the last case of what follows."

$ x="This is my test string."
$ echo ${x%% *}

This

#phép toán so sanh:
nhỏ hơn: $x -lt $y

awk 'FNR>=20 && FNR<=40' file