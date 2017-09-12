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
			sed -i "$i/$datadisk/$folder/ r," /etc/apparmor.d/usr.sbin.mysqld
			sed -i "$i/$datadisk/$folder/** rwk," /etc/apparmor.d/usr.sbin.mysqld
		fi
		old="_old"
		iOld="$folder$old"
		mv /var/lib/$folder /var/lib/$iOld
		ln -s /$datadisk/$folder /var/lib/$folder
	fi
done

service mysql start
if [ -f /etc/apparmor.d/usr.sbin.mysqld ]; then
	service apparmor restart
fi

if [ -d "/var/www/html" ]; then
	rsync -aux /var/www/html /$datadisk
	mv /var/www/html /var/www/html_old
	ln -s /$datadisk/html /var/www/html
fi