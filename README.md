# Melcloud2Domoticz
Tool for extracting data from Melcloud to Domoticz

Installation guide based on Debian

1) Requirements :

curl

-> sudo apt-get install curl

json 

-> sudo apt-get update && apt-get install npm

-> npm install -g json

# if you get a error about already exist, don't bother it ;)
-> ln -s /usr/bin/nodejs /usr/bin/node


2) Create folder and download script

mkdir -p /var/bin/melcloud

cd /var/bin/melcloud

wget https://raw.githubusercontent.com/AlbertHakvoort/Melcloud2Domoticz/master/melcloud2domoticz.sh

chmod +x melcloud2domoticz.sh



3) Add the following dummy devices in Domoticz:

5x dummy Temperature sensor

OUTDOORTEMP | ROOMTEMP | HEATFLOW | SWWTEMP | SWWSETPOINT

1x dummy Thermostat

SETPOINT

1x dummy Text

OPMODEZ1

2x dummy Switch

WPACTIVE | WPERROR


4) Edit melcloud2domoticz.sh and fill in : 

-> the IDX's to the corresponding devices 

-> username&password

-> Domoticz server ip and port


5) Start the script and check the output of it. Then check of the devices in Domoticz are updated.

/var/bin/melcloud/melcloud2domoticz.sh


6) If everything works fine add a job to the crontab

crontab -e

 * * * * *   /var/bin/melcloud/melcloud2domoticz.sh
