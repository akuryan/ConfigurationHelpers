#!/bin/bash

licenseKey=$1
appName=$2

echo deb http://apt.newrelic.com/debian/ newrelic non-free >> /etc/apt/sources.list.d/newrelic.list
wget -O- https://download.newrelic.com/548C16BF.gpg | apt-key add -
apt-get update
apt-get install newrelic-php5 -y
echo newrelic-php5 newrelic-php5/application-name string "$appName" | debconf-set-selections
echo newrelic-php5 newrelic-php5/license-key string "$licenseKey" | debconf-set-selections