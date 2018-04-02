#!/bin/bash
#Move Mysql and /var/www/html to /datadrive

datadisk=${1:-datadrive}

service mysql stop
#declare possible default folders for MySQL
declare -a arr=("mysql" "mysql-files" "mysql-keyring")

for folder in "${arr[@]}"
do
	if [ -d "/var/lib/$folder" ]; then
	  rsync -aux /var/lib/$folder /$datadisk
		if [ -f /etc/apparmor.d/usr.sbin.mysqld ]; then
			#maybe using "$ i" will fix this
			#or, maybe it is easier to replace old by new paths with smth like this: sed -i "s/bind-address.*/bind-address = 0.0.0.0/"
			#better is sed 's|/some/UNIX/path|/a/new/path|g' files
			sed -i "$i/$datadisk/$folder/ r," /etc/apparmor.d/usr.sbin.mysqld
			sed -i "$i/$datadisk/$folder/** rwk," /etc/apparmor.d/usr.sbin.mysqld
			
#datadisk="opt"
#folder="mysql"
#N=`grep -n "}" usr.sbin.mysqld | grep -Eo '^[^:]+'`
#echo $N
#sed -e $N"s/^/  \/$datadisk\/$folder\/ r\,\n/" -i usr.sbin.mysqld
#sed -e $N"s/^/  \/$datadisk\/$folder\/** rwk\,\n/" -i usr.sbin.mysqld
#cat usr.sbin.mysqld			
		fi
		old="_old"
		iOld="$folder$old"
		mv /var/lib/$folder /var/lib/$iOld
		ln -s /$datadisk/$folder /var/lib/$folder
	fi
done

if [ -f /etc/apparmor.d/usr.sbin.mysqld ]; then
	echo "check /etc/apparmor.d/usr.sbin.mysqld manually"
	sudo nano /etc/apparmor.d/usr.sbin.mysqld
	service apparmor restart
fi
service mysql start


if [ -d "/var/www/html" ]; then
	rsync -aux /var/www/html /$datadisk
	mv /var/www/html /var/www/html_old
	ln -s /$datadisk/html /var/www/html
fi