# Melcloud2Domoticz
Tool for extracting data from Melcloud to Domoticz

Installation guide based on Debian

1) Requirements :

curl

-> sudo apt-get update && apt-get install curl

json 

-> sudo apt-get install npm

-> npm install -g json

(some distro's dont have the right link to nodejs)

-> ln -s /usr/bin/nodejs /usr/bin/node


2) Create folder and download script

mkdir -p /var/bin/melcloud

cd /var/bin/melcloud

wget https://raw.githubusercontent.com/AlbertHakvoort/Melcloud2Domoticz/master/melcloud2domoticz.sh

chmod +x melcloud2domoticz.sh



3) Add the following dummy devices in Domoticz :

## Create 5x dummy Temperature sensor

IDXOUTDOORTEMP | IDXROOMTEMP | IDXHEATFLOW | IDXSWWTEMP | IDXSWWSETPOINT

## Create 1x dummy Thermostat

IDXSETPOINT (Setpoint of the thermostat)

## Create 1x dummy Text

IDXWPSTATUS (Shows the current status of the Unit Heating/SWW etc)

## Create 3x dummy Switch

IDXWPACTIVE (Is the unit running or not, can be used for scripts etc)

IDXWPERROR (Has the unit a error)

IDXWPPOWER (Is the Unit on or off)


## Create 1x Dummy Level selector

IDXWPMODE (change heat/cooling or thermostat/wdc)

Select "hide off level" and add the following levels:

10	Heating-Thermostat		
20	Heating-WaterTemp	 	
30	Heating-WDC	 	
40	Cooling-Thermostat	 	
50	Cooling-WaterTemp	 	
60	Cooling-WDC


4) Edit melcloud2domoticz.sh and fill in : 

-> the IDX's to the corresponding devices 

-> username&password

-> Domoticz server ip and port


5) Start the script and check the output of it. Then check of the devices in Domoticz are updated.

/var/bin/melcloud/melcloud2domoticz.sh

6) If everything works fine add a job to the crontab

crontab -e

  * * * * *   /var/bin/melcloud/melcloud2domoticz.sh
  
