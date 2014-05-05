	unset username
	unset password
	clear
	read -p "username:" username
	read -p "password:" -s password
	clear
	echo "Output:"
	echo "username: $username"
	echo "password: $password"
