#!/bin/bash

## Melcloud2Domoticz version 2.0.1 by albert[at]hakvoort[.]co

## Melcloud username/password
USERNAME=john@doe.com
PASSWORD=P@ssW0rd

## Domoticz Server Settings
SERVERIP=127.0.0.1
PORT=8080

## Script folder without trailing slash
FOLDER=/var/bin/melcloud

## Path
CAT=/bin/cat
CURL=/usr/bin/curl
JQ=/usr/bin/jq
PIDOF=/bin/pidof
GREP=/bin/grep
WC=/usr/bin/wc

## IDX Domoticz Settings

#Thermostat Setpoint
IDXSetHeatFlowTemperatureZone1=200

#Thermostat Setpoint
IDXSetCoolFlowTemperatureZone1=201

#Thermostat Setpoint
IDXSetTemperatureZone1=202

#Selector Switch
# 10 = Heating-Thermostat
# 20 = Heating-FlowTemp
# 30 = Heating-WDC
# 40 = Cooling-Thermostat
# 50 = Cooling-FlowTemp
IDXOperationModeZone1=203

#Switch
IDXPower=207

#Temperature
IDXOutdoorTemperature=209

#Temperature
IDXRoomTemperatureZone1=210

#Text
IDXProhibitZone1=213

#Text
IDXHeatpumpStatus=214

#Switch
IDXHeatpumpActive=215

## Set SWW to 0 if you're not using SWW, otherwise put 1 there

SWW=1

#Text
IDXEcoHotWater=206

#Temperature
IDXTankWaterTemperature=211

#Text
IDXProhibitHotWater=216

#Thermostat Setpoint
IDXSetTankWaterTemperature=204

#Switch
IDXForcedHotWaterMode=205


## Default settings if nothing received, for failsafe only
DOperationModeZone1=0
DSetTemperatureZone1=20
DSetHeatFlowTemperatureZone1=30
DSetCoolFlowTemperatureZone1=18
DSetTankWaterTemperature=50
DForcedHotWaterMode=false
DEcoHotWater=false
DForcedHotWaterMode=false
DTemperatureIncrementOverride=0

###########################################################################
#                   No changes are needed here below                      #
###########################################################################

DATA="/bin/cat $FOLDER/.data"
SEND2MELCLOUD=0


echo "-----------------------"
echo "Melcloud2Domoticz 2.0.1"
echo "-----------------------"

# check if we are the only local instance
if [[ "`$PIDOF -x $(basename $0) -o %PPID`" ]]; then
        echo "This script is already running with PID `$PIDOF -x $(basename $0) -o %PPID`"
        exit
fi

if [ ! -f $JQ ]; then
	echo "jq package is missing, check https://stedolan.github.io/jq/ or for Debian/Ubuntu -> apt-get install jq"
	exit
fi

if [ ! -f $CURL ]; then
	echo "curl is missing, or wrong path"
	exit
fi

if [ ! -f $CAT ]; then
	echo "cat is missing, or wrong path"
	exit
fi

if [ ! -f $PIDOF ]; then
	echo "pidof is missing, or wrong path"
	exit
fi

if [ ! -f $GREP ]; then
	echo "grep is missing, or wrong path"
	exit
fi

if [ ! -f $WC ]; then
	echo "wc is missing, or wrong path"
	exit
fi


## Check if Domoticz is online

CHECKDOMOTICZ=`$CURL --max-time 5 --connect-timeout 5 -s "http://$SERVERIP:$PORT/json.htm?type=command&param=getversion" | $JQ '.status' -r`

if [ "$CHECKDOMOTICZ" != "OK" ]; then
        echo "Domoticz unreachable at $SERVERIP:$PORT"
        exit
fi


## Login and get Session key

$CURL -s -o $FOLDER/.session 'https://app.melcloud.com/Mitsubishi.Wifi.Client/Login/ClientLogin' \
-H 'Cookie: policyaccepted=true; gsScrollPos-189=' \
-H 'Origin: https://app.melcloud.com' \
-H 'Accept-Encoding: gzip, deflate, br' \
-H 'Accept-Language: nl-NL,nl;q=0.9,en-NL;q=0.8,en;q=0.7,en-US;q=0.6,de;q=0.5' \
-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36' \
-H 'Content-Type: application/json; charset=UTF-8' \
-H 'Accept: application/json, text/javascript, */*; q=0.01' \
-H 'Referer: https://app.melcloud.com/' -H 'X-Requested-With: XMLHttpRequest' \
-H 'Connection: keep-alive' --data-binary '{"Email":'"\"$USERNAME\""',"Password":'"\"$PASSWORD\""',"Language":12,"AppVersion":"1.17.3.1","Persist":true,"CaptchaResponse":null}' --compressed ;

LOGINCHECK=`/bin/cat $FOLDER/.session | $JQ '.ErrorId'`

if [ $LOGINCHECK == "1" ]; then
	echo "----------------------------------"
	echo "|Wrong Melcloud login credentials|"
	echo "---------------------------------"
	exit
fi

SESSION=`cat $FOLDER/.session | $JQ '."LoginData"."ContextKey"' -r`

## Get Device/Building ID

$CURL -s -o $FOLDER/.deviceid 'https://app.melcloud.com/Mitsubishi.Wifi.Client/User/ListDevices' \
-H 'X-MitsContextKey: '"$SESSION"'' -H 'Accept-Encoding: gzip, deflate, br' \
-H 'Accept-Language: nl-NL,nl;q=0.9,en-NL;q=0.8,en;q=0.7,en-US;q=0.6,de;q=0.5' \
-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36' \
-H 'Accept: application/json, text/javascript, */*; q=0.01' \
-H 'Referer: https://app.melcloud.com/' \
-H 'X-Requested-With: XMLHttpRequest' \
-H 'Cookie: policyaccepted=true; gsScrollPos-189=' \
-H 'Connection: keep-alive' --compressed

## Check if there are multiple units, this script is only for 1 unit.

CHECKUNITS=`cat $FOLDER/.deviceid | $JQ '.' -r | $GREP DeviceID | $WC -l`

if [ $CHECKUNITS -gt 2 ]; then
	echo "Multiple units found, this script cannot yet handle more then 1 unit.."
	exit
fi

DEVICEID=`cat $FOLDER/.deviceid | $JQ '.' -r | grep DeviceID | head -n1 | cut -d : -f2 | xargs | sed 's/.$//'`
BUILDINGID=`cat $FOLDER/.deviceid | $JQ '.' -r | grep BuildingID | head -n1 | cut -d : -f2 | xargs | sed 's/.$//'`

echo DeviceID=$DEVICEID
echo BuildingID=$BUILDINGID

## Retrieve data from unit

$CURL -s -o $FOLDER/.data \
"https://app.melcloud.com/Mitsubishi.Wifi.Client/Device/Get?id=""$DEVICEID""&buildingID=""$BUILDINGID""" \
-H "X-MitsContextKey: ""$SESSION""" \
-H 'Accept-Encoding: gzip, deflate, br' \
-H 'Accept-Language: nl-NL,nl;q=0.9,en-NL;q=0.8,en;q=0.7,en-US;q=0.6,de;q=0.5' \
-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36' \
-H 'Accept: application/json, text/javascript, */*; q=0.01' \
-H 'Referer: https://app.melcloud.com/' \
-H 'X-Requested-With: XMLHttpRequest' \
-H 'Cookie: policyaccepted=true' \
-H 'Connection: keep-alive' --compressed

## Check if data output is fine

/bin/cat $FOLDER/.data | $JQ -e . >/dev/null 2>&1 

if [ ${PIPESTATUS[1]} != 0 ]; then
	echo "Retrieved Data is not json compatible, something went wrong....Help...."
	exit
fi

SetTemperatureZone1=`$DATA | $JQ '."SetTemperatureZone1"'`
RoomTemperatureZone1=`$DATA | $JQ '."RoomTemperatureZone1"'`
OperationMode=`$DATA | $JQ '."OperationMode"'`
OperationModeZone1=`$DATA | $JQ '."OperationModeZone1"'`
ErrorMessage=`$DATA | $JQ '."ErrorMessage"'`
SetHeatFlowTemperatureZone1=`$DATA | $JQ '."SetHeatFlowTemperatureZone1"'`
SetCoolFlowTemperatureZone1=`$DATA | $JQ '."SetCoolFlowTemperatureZone1"'`
TankWaterTemperature=`$DATA | $JQ '."TankWaterTemperature"'`
SetTankWaterTemperature=`$DATA | $JQ '."SetTankWaterTemperature"'`
ForcedHotWaterMode=`$DATA | $JQ '."ForcedHotWaterMode"'`
OutdoorTemperature=`$DATA | $JQ '."OutdoorTemperature"'`
EcoHotWater=`$DATA | $JQ '."EcoHotWater"'`
ProhibitZone1=`$DATA | $JQ '."ProhibitZone1"'`
ProhibitHotWater=`$DATA | $JQ '."ProhibitHotWater"'`
Power=`$DATA | $JQ '."Power"'`

## Convert OperationModes to text

	if [ "$OperationModeZone1" == "0" ]; then
       		OPMODEZONE1T="Heating-Thermostat"
			OPMODEZ1=10
	fi

	if [ "$OperationModeZone1" == "1" ]; then
       		OPMODEZONE1T="Heating-FlowTemp"
			OPMODEZ1=20
	fi

	if [ "$OperationModeZone1" == "2" ]; then
       		OPMODEZONE1T="Heating-WDC"
			OPMODEZ1=30
	fi

	if [ "$OperationModeZone1" == "3" ]; then
       		OPMODEZONE1T="Cooling-Thermostat"
			OPMODEZ1=40
	fi

	if [ "$OperationModeZone1" == "4" ]; then
			OPMODEZONE1T="Cooling-FlowTemp"
			OPMODEZ1=50
	fi

	if [ "$OperationMode" == "0" ]; then
       		OPMODE="Off"
	fi

	if [ "$OperationMode" == "1" ]; then
       		OPMODE="SWW"
	fi

	if [ "$OperationMode" == "2" ]; then
       		OPMODE="Heating"
	fi

	if [ "$OperationMode" == "3" ]; then
       		OPMODE="Cooling"
	fi

	if [ "$OperationMode" == "4" ]; then
       		OPMODE="Defrost??"
	fi
	
	if [ "$OperationMode" == "5" ]; then
		OPMODE="Standby"
	fi

	if [ "$OperationMode" == "6" ]; then
       		OPMODE="Legionella"
	fi
	
## Update Heatpump active switch (turns on when the heatpump is running, heating/cooling/defrosting and SWW)
	
DHeatpumpActive=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXHeatpumpActive" | $JQ -r '.result[]."Data"'`
	
	if [ $DHeatpumpActive == "Off" ] && [[ $OperationMode =~ [1-4,6] ]]; then
			echo "DHeatpumpActive = off | OperationMode > 0 or 5"
			$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=switchlight&idx=$IDXHeatpumpActive&switchcmd=On" > /dev/null
		else
			if [ $DHeatpumpActive == "On" ] && [[ $OperationMode =~ [0,5] ]]; then
				echo "DHeatpumpActive = on | OperationMode = 0"
				$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=switchlight&idx=$IDXHeatpumpActive&switchcmd=Off" > /dev/null
			fi
	fi
	
	
## Update Heatpump status text

DHeatpumpStatus=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXHeatpumpStatus" | $JQ -r '.result[]."Data"'`

	if [ "$OPMODE" != "$DHeatpumpStatus" ]; then
		$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXHeatpumpStatus&nvalue=0&svalue=$OPMODE"
	fi


## Update OutdoorTemperature
$CURL -q -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXOutdoorTemperature&nvalue=0&svalue=$OutdoorTemperature" > /dev/null

## Update RoomTemperatureZone1
$CURL -q -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXRoomTemperatureZone1&nvalue=0&svalue=$RoomTemperatureZone1" > /dev/null

## Update TankWaterTemperature

	if [ $SWW == "1" ]; then
		$CURL -q -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXTankWaterTemperature&nvalue=0&svalue=$TankWaterTemperature" > /dev/null
	fi
	
## Power status
DPower=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXPower" | $JQ -r '.result[]."Status"'`

if [ "$DPower" == "On" ]; then
       		DPower="true"
	else
			DPower="false"
	fi

if [ $DPower != $Power ]; then	
	echo "Update Power"
	SEND2MELCLOUD=1
fi

## SetTemperatureZone1
DSetTemperatureZone1=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXSetTemperatureZone1" | $JQ -r '.result[]."Data"'`
## Update DSetTemperatureZone1 (removes red time out bar in Domoticz)
$CURL -q -s "http://$SERVERIP:$PORT/json.htm?type=command&param=setsetpoint&idx=$IDXSetTemperatureZone1&setpoint=$DSetTemperatureZone1" > /dev/null

	## Remove .0 for comparison
	DSetTemperatureZone1="${DSetTemperatureZone1%.0}"

	if [ "$DSetTemperatureZone1" != "$SetTemperatureZone1" ]; then
			echo "Update SetTemperatureZone1"
			SEND2MELCLOUD=1
	fi

## SetHeatFlowTemperatureZone1
DSetHeatFlowTemperatureZone1=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXSetHeatFlowTemperatureZone1" | $JQ -r '.result[]."Data"'`
## Update SetHeatFlowTemperatureZone1 (removes red time out bar in Domoticz)
$CURL -q -s "http://$SERVERIP:$PORT/json.htm?type=command&param=setsetpoint&idx=$IDXSetHeatFlowTemperatureZone1&setpoint=$DSetHeatFlowTemperatureZone1" > /dev/null

	## Remove .0 for comparison
	DSetHeatFlowTemperatureZone1="${DSetHeatFlowTemperatureZone1%.0}"

	if [ "$DSetHeatFlowTemperatureZone1" != "$SetHeatFlowTemperatureZone1" ]; then
			echo "Update SetHeatFlowTemperatureZone1"
			SEND2MELCLOUD=1
	fi

## SetCoolFlowTemperatureZone1
DSetCoolFlowTemperatureZone1=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXSetCoolFlowTemperatureZone1" | $JQ -r '.result[]."Data"'`
## Update SetCoolFlowTemperatureZone1 (removes red time out bar in Domoticz)
$CURL -q -s "http://$SERVERIP:$PORT/json.htm?type=command&param=setsetpoint&idx=$IDXSetCoolFlowTemperatureZone1&setpoint=$DSetCoolFlowTemperatureZone1" > /dev/null

	## Remove .0 for comparison
	DSetCoolFlowTemperatureZone1="${DSetCoolFlowTemperatureZone1%.0}"

	if [ "$DSetCoolFlowTemperatureZone1" != "$SetCoolFlowTemperatureZone1" ]; then
			echo "Update SetCoolFlowTemperatureZone1"
			SEND2MELCLOUD=1
	fi
	
## SetTankWaterTemperature
	if [ $SWW == "1" ]; then
DSetTankWaterTemperature=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXSetTankWaterTemperature" | $JQ -r '.result[]."Data"'`
## Update SetTankWaterTemperature (removes red time out bar in Domoticz)
$CURL -q -s "http://$SERVERIP:$PORT/json.htm?type=command&param=setsetpoint&idx=$IDXSetTankWaterTemperature&setpoint=$DSetTankWaterTemperature" > /dev/null

	## Remove .0 for comparison
	DSetTankWaterTemperature="${DSetTankWaterTemperature%.0}"

	if [ "$DSetTankWaterTemperature" != "$SetTankWaterTemperature" ]; then
		echo "Update SetTankWaterTemperature"
		SEND2MELCLOUD=1
		fi
	fi

## OperationModeZone1
DOperationModeZone1=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXOperationModeZone1" | $JQ -r '.result[]."Level"'`

	if [ "$DOperationModeZone1" -ne "$OPMODEZ1" ]; then
			
			echo "Update OperationModeZone1"
			
			if [ "$DOperationModeZone1" == "10" ]; then
				DOperationModeZone1=0
			fi
			
			if [ "$DOperationModeZone1" == "20" ]; then
				DOperationModeZone1=1
			fi
			
			if [ "$DOperationModeZone1" == "30" ]; then
				DOperationModeZone1=2
			fi
			
			if [ "$DOperationModeZone1" == "40" ]; then
				DOperationModeZone1=3
			fi
			
			if [ "$DOperationModeZone1" == "50" ]; then
				DOperationModeZone1=4
			fi
			
		SEND2MELCLOUD=1
	fi
			
			
## ForcedHotWaterMode

	if [ $SWW == "1" ]; then
	DForcedHotWaterMode=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXForcedHotWaterMode" | $JQ -r '.result[]."Data"'`

		if [ "$DForcedHotWaterMode" == "On" ]; then
				echo "ForcedHotWaterMode is on"
				DForcedHotWaterMode=true
				$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=switchlight&idx=$IDXForcedHotWaterMode&switchcmd=Off"		
				SEND2MELCLOUD=1
			else
				DForcedHotWaterMode=false
		fi
	fi
	
## EcoHotWater

	if [ $SWW == "1" ]; then
		DEcoHotWater=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXEcoHotWater" | $JQ -r '.result[]."Data"'`

		if [ "$DEcoHotWater" != "$EcoHotWater" ]; then
				$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXEcoHotWater&nvalue=0&svalue=$EcoHotWater"
				echo "Updating EcoHotWater text"
		fi
	fi
	
## ProhibitZone1
DProhibitZone1=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXProhibitZone1" | $JQ -r '.result[]."Data"'`


	if [ "$DProhibitZone1" != "$ProhibitZone1" ]; then
				$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXProhibitZone1&nvalue=0&svalue=$ProhibitZone1"
				echo "Updating ProhibitZone1 text"
	fi
	
## ProhibitHotWater
	if [ $SWW == "1" ]; then
		DProhibitHotWater=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXProhibitHotWater" | $JQ -r '.result[]."Data"'`


		if [ "$DProhibitHotWater" != "$ProhibitHotWater" ]; then
				$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXProhibitHotWater&nvalue=0&svalue=$ProhibitHotWater"
				echo "Updating ProhibitHotWater text"
		fi
	fi
	
echo "SetTemperatureZone1=$SetTemperatureZone1"
echo "RoomTemperatureZone1=$RoomTemperatureZone1"
echo "OperationMode=$OperationMode:$OPMODE"
echo "OperationModeZone1=$OperationModeZone1:$OPMODEZONE1T"
echo "ErrorMessage=$ErrorMessage"
echo "SetHeatFlowTemperatureZone1=$SetHeatFlowTemperatureZone1"
echo "SetCoolFlowTemperatureZone1=$SetCoolFlowTemperatureZone1"
echo "OutdoorTemperature=$OutdoorTemperature"
echo "ProhibitZone1=$ProhibitZone1"
echo "Power=$Power"

if [ $SWW == "1" ]; then
		echo "TankWaterTemperature=$TankWaterTemperature"
		echo "SetTankWaterTemperature=$SetTankWaterTemperature"
		echo "ForcedHotWaterMode=$ForcedHotWaterMode"
		echo "ProhibitHotWater=$ProhibitHotWater"
		echo "EcoHotWater=$EcoHotWater"
	else
		echo "SWW=disabled"
fi
	
if [ "$SEND2MELCLOUD" == "1" ]; then

echo "Updating Melcloud settings"

# EffectiveFlags settings
# temp		8589934592
# sww/flow	281474976710688
# mode		8
# power		1
# force sww 65536
# all 		281483566710825

$CURL -s -o $FOLDER/.send 'https://app.melcloud.com/Mitsubishi.Wifi.Client/Device/SetAtw' -H 'X-MitsContextKey: '"$SESSION"'' \
-H 'Origin: https://app.melcloud.com' -H 'Accept-Encoding: gzip, deflate, br' \
-H 'Accept-Language: nl-NL,nl;q=0.9,en-NL;q=0.8,en;q=0.7,en-US;q=0.6,de;q=0.5' \
-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36' \
-H 'Content-Type: application/json; charset=UTF-8' \
-H 'Accept: application/json, text/javascript, */*; q=0.01' \
-H 'Referer: https://app.melcloud.com/' \
-H 'X-Requested-With: XMLHttpRequest' \
-H 'Cookie: policyaccepted=true; gsScrollPos-2=0' \
-H 'Connection: keep-alive' --data-binary '{"EffectiveFlags":281483566710825,"SetTemperatureZone1":'$DSetTemperatureZone1',"OperationModeZone1":'$DOperationModeZone1',"SetHeatFlowTemperatureZone1":'$DSetHeatFlowTemperatureZone1',"SetCoolFlowTemperatureZone1":'$DSetCoolFlowTemperatureZone1',"HCControlType":1,"SetTankWaterTemperature":'$DSetTankWaterTemperature',"ForcedHotWaterMode":'$DForcedHotWaterMode',"TemperatureIncrementOverride":'$DTemperatureIncrementOverride',"DeviceID":'"$DEVICEID"',"DeviceType":1,"Power":'"$DPower"',"HasPendingCommand":true,"Offline":false,"Scene":null,"SceneOwner":null}' --compressed

cat $FOLDER/.send | jq '.'

fi
