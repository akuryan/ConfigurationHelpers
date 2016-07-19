#!/bin/bash

licenseKey=$1

echo deb http://apt.newrelic.com/debian/ newrelic non-free >> /etc/apt/sources.list.d/newrelic.list
wget -O- https://download.newrelic.com/548C16BF.gpg | apt-key add -
apt-get update
apt-get install newrelic-sysmond -y
nrsysmond-config --set license_key=$licenseKey
/etc/init.d/newrelic-sysmond start