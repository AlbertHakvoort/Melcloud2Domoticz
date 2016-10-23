#!/bin/bash

## Ecodan Domoticz plugin
## version 0.6
## (c) albert [at] hakvoort [dot] co

## This version is only suitable for 1 device/building !!

## Melcloud login settings
USERNAME=john@doe.com
PASSWORD=JaneDoe1

## No trailing slash at the end of the folder path!
FOLDER=/var/bin/melcloud

## Domoticz Server Settings
SERVERIP=127.0.0.1
PORT=8080

########################################################## 
#              Domoticz dummy Devices IDX's              #
##########################################################

## Create 5x dummy Temperature sensor

IDXOUTDOORTEMP=81
IDXROOMTEMP=82
IDXHEATFLOW=84
IDXSWWTEMP=86
IDXSWWSETPOINT=87

## Create 1x dummy Thermostat

IDXSETPOINT=83

## Create 1x dummy Text

IDXOPMODEZ1=85

## Create 2x dummy Switch

IDXWPACTIVE=88
IDXWPERROR=89



## Check Path (Debian Default)

JSON=/usr/local/bin/json
CURL=/usr/bin/curl
HEAD=/usr/bin/head
AWK=/usr/bin/awk
SED=/bin/sed
TR=/usr/bin/tr
GREP=/bin/grep
CAT=/bin/cat

PATH=/var/bin:/bin:/usr/bin:/usr/local/bin


############################################################## 
#             No need for changes below this line            #
############################################################## 

echo "Melcloud to Domoticz tool version 0.6"

## Check if Domoticz is up&running

CHECKDOMOTICZ=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=getversion" | $GREP status | $AWK '{print $3;}' | $SED 's/"//' | $TR -d ',' | $TR -d '"'`

if [ "$CHECKDOMOTICZ" != "OK" ]; then
        echo "Domoticz unreachable at $SERVERIP:$PORT"
        exit
fi

if [ ! -f $FOLDER/settings.ini ]; then

if [ ! -f $JSON ]; then
	echo "JSON package is missing, check https://github.com/trentm/json"
	exit
fi

if [ ! -f $CURL ]; then
	echo "curl is missing, or wrong path"
	exit
fi

if [ ! -f $HEAD ]; then
	echo "head is missing, or wrong path"
	exit
fi

if [ ! -f $AWK ]; then
	echo "awk is missing, or wrong path"
	exit
fi

if [ ! -f $SED ]; then
	echo "sed is missing, or wrong path"
	exit
fi

if [ ! -f $TR ]; then
	echo "tr is missing, or wrong path"
	exit
fi

if [ ! -f $CAT ]; then
	echo "cat is missing, or wrong path"
	exit
fi


echo "Settings file not found, retrieve from Melcloud" 

### Get login key

LOGIN="$CURL -s 'https://app.melcloud.com/Mitsubishi.Wifi.Client/Login/ClientLogin' -H 'Origin: https://app.melcloud.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: nl-NL,nl;q=0.8,en-US;q=0.6,en;q=0.4,af;q=0.2,de;q=0.2,lt;q=0.2,es;q=0.2' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36' -H 'Content-Type: application/json; charset=UTF-8' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: https://app.melcloud.com/' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' --data-binary '{\"Email\":\"$USERNAME\",\"Password\":\"$PASSWORD\",\"Language\":12,\"AppVersion\":\"1.11.2.0\",\"Persist\":false,\"CaptchaChallenge\":null,\"CaptchaResponse\":null}' --compressed"

echo $LOGIN > $FOLDER/temp.sh

chmod +x $FOLDER/temp.sh

KEY=`$FOLDER/temp.sh | $JSON "LoginData" | $JSON "ContextKey"`

### Check if login key is received, if not check login credentials

if [ -z "$KEY" ]; then
	LOGINCHECK=`$FOLDER/temp.sh | $JSON | $JSON ErrorId`
	if [ $LOGINCHECK == "1" ]; then
	echo "Wrong login credentials,please check username and password"
	exit
	fi
fi

echo $KEY > $FOLDER/settings.ini

### Get building and device id

LIST="$CURL -s 'https://app.melcloud.com/Mitsubishi.Wifi.Client/User/ListDevices' -H 'X-MitsContextKey: $KEY' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: nl-NL,nl;q=0.8,en-US;q=0.6,en;q=0.4,af;q=0.2,de;q=0.2,lt;q=0.2,es;q=0.2' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: https://app.melcloud.com/' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' --compressed"

echo $LIST > $FOLDER/temp.sh

chmod +x $FOLDER/temp.sh

LIST=`$FOLDER/temp.sh`

DEVICEID=`echo $LIST | $JSON | $GREP DeviceID | $HEAD -n 1 | $AWK '{print $2;}' | $SED 's/,//'`
BUILDINGID=`echo $LIST | $JSON | $GREP BuildingID | $HEAD -n 1 | $AWK '{print $2;}' | $SED 's/,//'`

echo $DEVICEID >> $FOLDER/settings.ini
echo $BUILDINGID >> $FOLDER/settings.ini

fi

### Get settings from the settings.ini

KEY=`$CAT $FOLDER/settings.ini | $SED -n '1p'`
DEVICEID=`$CAT $FOLDER/settings.ini | $SED -n '2p'`
BUILDINGID=`$CAT $FOLDER/settings.ini | $SED -n '3p'`

### Check login and retrieve the data

GET="$CURL -s 'https://app.melcloud.com/Mitsubishi.Wifi.Client/Device/Get?id=$DEVICEID&buildingID=$BUILDINGID' -H 'X-MitsContextKey: $KEY' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: nl-NL,nl;q=0.8,en-US;q=0.6,en;q=0.4,af;q=0.2,de;q=0.2,lt;q=0.2,es;q=0.2' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: https://app.melcloud.com/' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' --compressed" 

echo $GET > $FOLDER/temp.sh

chmod +x $FOLDER/temp.sh

DATA=`$FOLDER/temp.sh`

LOGINCHECK=`echo $DATA |  $GREP Success | cut -d: -f2 | cut -d, -f1`

if [[ $LOGINCHECK == "false" ]]; then
	echo "Login KEY is wrong or expired. Auto removing the settings.ini, so the credentials will be renewed. If still not working check username and password!"
	rm $FOLDER/settings.ini
	exit
fi


### Check retrieved JSON file, if wrong delete login key

echo $DATA | $JSON -n -q

if [[ $? != 0 ]]; then
        echo "Wrong data, session expired, removing expired login key"
	rm $FOLDER/settings.ini
	exit
fi


OUTDOORTEMP=`echo $DATA | $JSON "OutdoorTemperature"`
ROOMTEMP=`echo $DATA | $JSON "RoomTemperatureZone1"`

echo "Update Outdoor Temp"

$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXOUTDOORTEMP&nvalue=0&svalue=$OUTDOORTEMP"

echo "Update Room Temp"

$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXROOMTEMP&nvalue=0&svalue=$ROOMTEMP"

### Read setpoint from Json and send it to Domoticz

echo "Update Set Point"

SETPOINT=`echo $DATA | $JSON "SetTemperatureZone1"`

$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXSETPOINT&nvalue=0&svalue=$SETPOINT"

## Read Heatflow from Json and send it to Domoticz

echo "Update Heatflow Temp"

HEATFLOW=`echo $DATA | $JSON "SetHeatFlowTemperatureZone1"`

$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXHEATFLOW&nvalue=0&svalue=$HEATFLOW"

### Convert Operation mode to text

OPMODEZONE1=`echo $DATA | json "OperationModeZone1"`

	if [ "$OPMODEZONE1" == "0" ]; then
       		 OPMODEZONE1="Heating-Thermostat"
	fi

	if [ "$OPMODEZONE1" == "1" ]; then
       		 OPMODEZONE1="Heating-FlowTemp"
	fi

	if [ "$OPMODEZONE1" == "2" ]; then
       		 OPMODEZONE1="Heating-WAR"
	fi

	if [ "$OPMODEZONE1" == "3" ]; then
       		 OPMODEZONE1="Cooling-Thermostat"
	fi

	if [ "$OPMODEZONE1" == "4" ]; then
       		 OPMODEZONE1="Cooling-FlowTemp"
	fi

	if [ "$OPMODEZONE1" == "4" ]; then
       		 OPMODEZONE1="Cooling-WAR"
	fi

CHECKOPMODEZ1=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXOPMODEZ1" | $GREP Data | $AWK '{print $3;}' | $SED 's/"//' | $TR -d ',' | $TR -d '"'`

if [ "$CHECKOPMODEZ1" != "$OPMODEZONE1" ]; then
	/bin/echo "Update Operation Mode"
        $CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXOPMODEZ1&nvalue=0&svalue=$OPMODEZONE1"
fi

echo "Update SWW Temp"

SWWTEMP=`echo $DATA | $JSON "TankWaterTemperature"`
$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXSWWTEMP&nvalue=0&svalue=$SWWTEMP"

echo "Update SWW Setpoint"

SWWSETPOINT=`echo $DATA | $JSON "SetTankWaterTemperature"`
$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXSWWSETPOINT&nvalue=0&svalue=$SWWSETPOINT"


OPMODE=`echo $DATA | $JSON "OperationMode"`


if [ "$OPMODE" == "2" ]; then
        OPMODE="Heating"
fi

if [ "$OPMODE" == "3" ]; then
        OPMODE="Cooling"
fi

if [ "$OPMODE" == "1" ]; then
        OPMODE="SWW"
fi

if [ "$OPMODE" == "0" ]; then
        OPMODE="Off"
fi

if [ "$OPMODE" == "5" ]; then
        OPMODE="Standby"
fi

if [ "$OPMODE" == "6" ]; then
        OPMODE="Legionella"
fi

CHECKWPACTIVE=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXWPACTIVE" | $GREP Data | $AWK '{print $3;}' | $SED 's/"//' | $TR -d ',' | $TR -d '"'`

if [ "$OPMODE" == "Off" ]; then
	if [ "$CHECKWPACTIVE" != "Off" ]; then
	/bin/echo "Update Operation Mode"
        curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=switchlight&idx=$IDXWPACTIVE&switchcmd=Off"
	fi
else
	if [ "$CHECKWPACTIVE" != "On" ]; then
	/bin/echo "Update Operation Mode"
        curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=switchlight&idx=$IDXWPACTIVE&switchcmd=On"
	fi
fi

WPERROR=`echo $DATA | $JSON "ErrorMessage"`

if [ "$WPERROR" == "null" ]; then
        WPERROR=0
else
        WPERROR=1
fi

CHECKWPERROR=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXWPERROR" | $GREP Data | $AWK '{print $3;}' | $SED 's/"//' | $TR -d ',' | $TR -d '"'`

if [ "$WPERROR" == "0" ]; then
        if [ "$CHECKWPERROR" != "Off" ]; then
        /bin/echo "Update Error Status"
        curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=switchlight&idx=$IDXWPERROR&switchcmd=Off"
        fi
else
        if [ "$CHECKWPERROR" != "On" ]; then
        /bin/echo "Update Error Status"
        curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=switchlight&idx=$IDXWPERROR&switchcmd=On"
        fi
fi


