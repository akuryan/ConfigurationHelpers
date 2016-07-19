#!/bin/bash

licenseKey=$1
appName=$2

echo newrelic-php5 newrelic-php5/application-name string "$appName" | debconf-set-selections
echo newrelic-php5 newrelic-php5/license-key string "$licenseKey" | debconf-set-selections
apt-get install newrelic-php5 -y
service apache2 restart