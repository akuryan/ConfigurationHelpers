#!/bin/bash
# set up a silent install of MySQL
dbpass=$1

export DEBIAN_FRONTEND=noninteractive
echo mysql-server-5.6 mysql-server/root_password password $dbpass | debconf-set-selections
echo mysql-server-5.6 mysql-server/root_password_again password $dbpass | debconf-set-selections

apt-get update
apt-get install -y mysql-client mysql-server automysqlbackup

# Allow remote connection
sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
service mysql restart