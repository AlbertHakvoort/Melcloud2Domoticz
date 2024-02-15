This script is to old, please check this forum post for a updated script :

https://gathering.tweakers.net/forum/view_message/78141334


#############################################################################

>>>>> Old, do NOT use anymore, Melcloud wil block your account <<<<<<


#############################################################################



# Melcloud2Domoticz 2.0.1

Tool for extracting data from Melcloud Ecodan to Domoticz (only 1x Air/Water unit!! Air/Air isn't working)

--> !! Domoticz is leading, so changes made in Melcloud are overruled by Domoticz (next version will have 2way sync)

--> !! Disable any timer/scheduler in Melcloud

Installation guide based on Debian

## 1) Requirements :

curl and jq (https://stedolan.github.io/jq/)

-> sudo apt-get install curl jq

## 2) Create folder and download script

mkdir -p /var/bin/melcloud

cd /var/bin/melcloud

wget https://raw.githubusercontent.com/AlbertHakvoort/Melcloud2Domoticz/master/melcloud2domoticz.sh

chmod +x melcloud2domoticz.sh



## 3) Add the following dummy devices in Domoticz :

- Create 3x dummy Temperature sensor

OutdoorTemperature | RoomTemperatureZone1 | TankWaterTemperature

- Create 4x dummy Thermostat Setpoint

SetHeatFlowTemperatureZone1 | SetCoolFlowTemperatureZone1 | SetTemperatureZone1 | SetTankWaterTemperatur

- Create 4x dummy Text

ProhibitZone1 | HeatpumpStatus | EcoHotWater | ProhibitHotWater | 

- Create 3x dummy Switch

HeatpumpPower | HeatpumpActive | ForcedHotWaterMode

- Create 1x Dummy Level selector

OperationModeZone1 (change heat/cooling or thermostat/wdc)

Select "hide off level" and add the following levels:

10	Heating-Thermostat

20	Heating-WaterTemp
 	
30	Heating-WDC

40	Cooling-Thermostat
	
50	Cooling-WaterTemp


## 4) Edit melcloud2domoticz.sh and fill in : 

-> the IDX's to the corresponding devices 

-> username&password

-> Domoticz server ip and port

-> path of the used programs


## 5) Start the script and check the output of it. Then check of the devices in Domoticz are updated.

/var/bin/melcloud/melcloud2domoticz.sh (when running as non-root user use sudo!)

## 6) If everything works fine add a job to the crontab

crontab -e

  */2 * * * *   /var/bin/melcloud/melcloud2domoticz.sh
  
  (since the december 2021 firmware update the time must be changed from 1 to 2 minutes)
  
