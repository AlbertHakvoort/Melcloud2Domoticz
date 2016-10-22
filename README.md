# Melcloud
Tool for extracting data from Melcloud to Domoticz

Installation guide based on Debian

Requirements :

curl
-> apt-get install curl

json 
-> apt-get install npm
-> npm install -g json
-> ln -s /usr/bin/nodejs /usr/bin/node

mkdir -p /var/bin/melcloud

cd /var/bin/melcloud

wget https://raw.githubusercontent.com/AlbertHakvoort/Melcloud2Domoticz/master/melcloud2domoticz.sh

chmod +x melcloud2domoticz.sh

Add the following dummy devices in Domoticz

5x dummy Temperature sensor

OUTDOORTEMP
ROOMTEMP
HEATFLOW
SWWTEMP
SWWSETPOINT

1x dummy Thermostat

SETPOINT

1x dummy Text

OPMODEZ1

2x dummy Switch

WPACTIVE
WPERROR
