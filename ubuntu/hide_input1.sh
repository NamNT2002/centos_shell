unset username
unset password
clear
read -p "username:" username
prompt="password:"
while IFS= read -p "$prompt" -r -s -n 1 char
do
    if [[ $char == $'\0' ]]
    then
         break
    fi
    prompt='*'
    password+="$char"
done
clear
echo "Output:"
echo "username: $username"
echo "password: $password"


