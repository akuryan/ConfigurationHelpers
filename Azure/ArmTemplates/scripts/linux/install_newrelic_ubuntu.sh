#!/bin/bash

licenseKey=$1

apt-get install newrelic-sysmond -y
nrsysmond-config --set license_key=$licenseKey
/etc/init.d/newrelic-sysmond start