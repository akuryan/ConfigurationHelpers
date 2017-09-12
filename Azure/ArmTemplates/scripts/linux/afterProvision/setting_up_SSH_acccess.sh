#!/bin/bash
#This script will get public keys for users from Github and install them as managementUser authorized keys (user name can be overriden if set as parameter)

user=${1:-managementUser}

declare -a arr=("akuryan" "Kinstintin" "deployer-colours-minsk")

## now loop through the above array
for i in "${arr[@]}"
do
	key=""
	key="$(curl https://github.com/$i.keys 2>/dev/null)"
	key="$key $i"
	echo $key >> /home/$user/.ssh/authorized_keys
done

# You can access them using echo "${arr[0]}", "${arr[1]}" also

