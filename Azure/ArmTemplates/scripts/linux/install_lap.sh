#!/bin/bash

# Install required packages
echo "installing required packages"
until apt-get -y update && apt-get -y install apache2 php5 php5-gd php5-mysql mysql-client git 
do
echo "installing required packages....."
sleep 2
done

# write some PHP
echo \<center\>\<h1\>My Demo App\</h1\>\<br/\>\</center\> > /var/www/html/phpinfo.php
echo \<\?php phpinfo\(\)\; \?\> >> /var/www/html/phpinfo.php

# restart Apache
apachectl restart