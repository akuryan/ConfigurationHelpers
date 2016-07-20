#!/bin/bash
licenseKey=$1
# Install required packages
echo "installing required packages"
apt-get -y update
apt-get -y install apache2 php5 php5-gd php5-mysql mysql-client git unzip

# write some PHP
echo \<center\>\<h1\>My Demo App\</h1\>\<br/\>\</center\> > /var/www/html/phpinfo.php
echo \<\?php phpinfo\(\)\; \?\> >> /var/www/html/phpinfo.php

#Do some defaul Apache setup
#Enable rewrite
a2enmod rewrite
a2enmod headers
#Set index.php as default doc
if [ -f /etc/apache2/mods-enabled/dir.conf ]
then
	echo \<IfModule mod_dir.c\> > /etc/apache2/mods-enabled/dir.conf
	echo DirectoryIndex index.php index.html >> /etc/apache2/mods-enabled/dir.conf
	echo \</IfModule\> >> /etc/apache2/mods-enabled/dir.conf
fi

#Enable .htaccess and other not really secure stuff
if [ -f /etc/apache2/sites-enabled/000-default.conf ]
then
	echo \<VirtualHost *:80\> > /etc/apache2/sites-enabled/000-default.conf
		echo ServerAdmin a.kuryan@colours.nl >> /etc/apache2/sites-enabled/000-default.conf
        echo DocumentRoot /var/www/html >> /etc/apache2/sites-enabled/000-default.conf
        echo \<Directory /var/www/html/\> >> /etc/apache2/sites-enabled/000-default.conf
                echo Options +Indexes +FollowSymLinks +MultiViews >> /etc/apache2/sites-enabled/000-default.conf
                echo AllowOverride All >> /etc/apache2/sites-enabled/000-default.conf
                echo Order allow,deny >> /etc/apache2/sites-enabled/000-default.conf
                echo allow from all >> /etc/apache2/sites-enabled/000-default.conf
        echo \</Directory\> >> /etc/apache2/sites-enabled/000-default.conf
        echo RewriteEngine On >> /etc/apache2/sites-enabled/000-default.conf
        echo RewriteOptions inherit >> /etc/apache2/sites-enabled/000-default.conf
        echo ErrorLog ${APACHE_LOG_DIR}/error.log >> /etc/apache2/sites-enabled/000-default.conf
        echo CustomLog ${APACHE_LOG_DIR}/access.log combined >> /etc/apache2/sites-enabled/000-default.conf
        echo RequestHeader unset Proxy >> /etc/apache2/sites-enabled/000-default.conf
	echo \</VirtualHost\> >> /etc/apache2/sites-enabled/000-default.conf
fi

# restart Apache
apachectl restart

echo deb http://apt.newrelic.com/debian/ newrelic non-free >> /etc/apt/sources.list.d/newrelic.list
wget -O- https://download.newrelic.com/548C16BF.gpg | apt-key add -
apt-get update
apt-get install newrelic-sysmond -y
nrsysmond-config --set license_key=$licenseKey
/etc/init.d/newrelic-sysmond start
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
apt-get install -y iptables-persistent
