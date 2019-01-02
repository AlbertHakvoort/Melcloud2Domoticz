# Melcloud2Domoticz 

Tool for extracting data from Melcloud to Domoticz 

Installation guide based on Debian

## 1) Requirements :

curl

-> sudo apt-get update && apt-get install curl

jq 

-> sudo apt-get install jq ( or https://stedolan.github.io/jq/ )

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


## 5) Start the script and check the output of it. Then check of the devices in Domoticz are updated.

/var/bin/melcloud/melcloud2domoticz.sh

## 6) If everything works fine add a job to the crontab

crontab -e

  */1 * * * *   /var/bin/melcloud/melcloud2domoticz.sh
  
