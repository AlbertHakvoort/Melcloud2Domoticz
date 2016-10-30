#!/bin/bash

## Ecodan Domoticz plugin
## version 0.9
## (c) albert [at] hakvoort [dot] co

## This version is only suitable for 1 device/building !!

## Melcloud login settings
USERNAME=john@doe.com
PASSWORD=JaneDoe123

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

IDXWPSTATUS=85

## Create 3x dummy Switch

IDXWPACTIVE=88
IDXWPERROR=89
IDXWPPOWER=108

## Create 1x Dummy Level selector

IDXWPMODE=91

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

MELCLOUDSEND=0
MELCLOUDSTOP=0
OPMODEZONE=0

echo "Melcloud to Domoticz tool version 0.9"

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

if [[ "$LOGINCHECK" == "false" ]]; then
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

### Check power status unit

POWER=`echo $DATA | $JSON "Power"`

CHECKWPPOWER=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXWPPOWER" | $GREP Data | $AWK '{print $3;}' | $SED 's/"//' | $TR -d ',' | $TR -d '"'`
LASTUPDATEWPPOWER=`curl -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXWPPOWER" | json | grep LastUpdate | cut -d\" -f4`
TIMESTAMPWPMODE=$(date +%s)

DAY=`echo $LASTUPDATEWPPOWER | cut -d- -f3 | cut -d" " -f1`
MONTH=`echo $LASTUPDATEWPPOWER | cut -d- -f2`
YEAR=`echo $LASTUPDATEWPPOWER | cut -d- -f1`
TIME=`echo $LASTUPDATEWPPOWER | awk '{print $2}'`

CONVERTWPPOWER=`date -d "$YEAR-$MONTH-$DAY"T"$TIME" "+%s"`

DIFWPMODE=`expr $TIMESTAMPWPMODE - $CONVERTWPPOWER`

SETPOWER=skip

if [ "$DIFWPMODE" -lt "60" ]; then
        echo "WP Power button changed"
        	if [ "$CHECKWPPOWER" != "Off" ]; then
			SETPOWER=true
			echo "Set power on"
		else
			SETPOWER=false
			echo "Set power off"
		fi

fi

if [ "$SETPOWER" == "skip" ]; then
	echo "No power changes"
	else

CMD="$CURL -s 'https://app.melcloud.com/Mitsubishi.Wifi.Client/Device/SetAtw' -H 'Pragma: no-cache' -H 'Origin: https://app.melcloud.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: nl-NL,nl;q=0.8,en-US;q=0.6,en;q=0.4,af;q=0.2,de;q=0.2,lt;q=0.2,es;q=0.2' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36' -H 'Content-Type: application/json; charset=UTF-8' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Cache-Control: no-cache' -H 'X-MitsContextKey: $KEY' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'Referer: https://app.melcloud.com/' --data-binary '{\"EffectiveFlags\":1,\"LocalIPAddress\":null,\"DeviceID\":$DEVICEID,\"DeviceType\":1,\"LastCommunication\":\"2016-10-29T14:15:48.85\",\"NextCommunication\":\"2016-10-29T14:16:48.85\",\"Power\":$SETPOWER,\"HasPendingCommand\":true,\"Offline\":false}' --compressed"

echo $CMD > $FOLDER/temp.sh
chmod +x $FOLDER/temp.sh
$FOLDER/temp.sh
exit

fi



if [ "$POWER" == "false" ]; then

        if [ "$CHECKWPPOWER" != "Off" ]; then
        /bin/echo "Update Power status to Off"
        curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=switchlight&idx=$IDXWPPOWER&switchcmd=Off"
        fi
else
        if [ "$CHECKWPPOWER" != "On" ]; then
        /bin/echo "Update Power status to On"
        curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=switchlight&idx=$IDXWPPOWER&switchcmd=On"
        fi
fi



OUTDOORTEMP=`echo $DATA | $JSON "OutdoorTemperature"`
ROOMTEMP=`echo $DATA | $JSON "RoomTemperatureZone1"`

echo "Update Outdoor Temp"

$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXOUTDOORTEMP&nvalue=0&svalue=$OUTDOORTEMP"

echo "Update Room Temp"

$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXROOMTEMP&nvalue=0&svalue=$ROOMTEMP"

## Read Heatflow from Json and send it to Domoticz


echo "Update Heatflow Temp"

HEATFLOW=`echo $DATA | $JSON "SetHeatFlowTemperatureZone1"`

$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXHEATFLOW&nvalue=0&svalue=$HEATFLOW"

### Convert Operation mode to text

OPMODEZONE1=`echo $DATA | json "OperationModeZone1"`

	if [ "$OPMODEZONE1" == "0" ]; then
       		 OPMODEZONE1T="Heating-Thermostat"
		 OPMODEZ1=10
	fi

	if [ "$OPMODEZONE1" == "1" ]; then
       		 OPMODEZONE1T="Heating-FlowTemp"
		 OPMODEZ1=20
	fi

	if [ "$OPMODEZONE1" == "2" ]; then
       		 OPMODEZONE1T="Heating-WDC"
		 OPMODEZ1=30
	fi

	if [ "$OPMODEZONE1" == "3" ]; then
       		 OPMODEZONE1T="Cooling-Thermostat"
		 OPMODEZ1=40
	fi

	if [ "$OPMODEZONE1" == "4" ]; then
       		 OPMODEZONE1T="Cooling-FlowTemp"
		 OPMODEZ1=50
	fi

	if [ "$OPMODEZONE1" == "4" ]; then
       		 OPMODEZONE1T="Cooling-WDC"
		 OPMODEZ1=60
	fi

echo "Operation mode is $OPMODEZONE1T"


# Check when OperationMode was changed

LASTUPDATEWPMODE=`curl -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXWPMODE" | json | grep LastUpdate | cut -d\" -f4`
TIMESTAMPWPMODE=$(date +%s)

DAY=`echo $LASTUPDATEWPMODE | cut -d- -f3 | cut -d" " -f1`
MONTH=`echo $LASTUPDATEWPMODE | cut -d- -f2`
YEAR=`echo $LASTUPDATEWPMODE | cut -d- -f1`
TIME=`echo $LASTUPDATEWPMODE | awk '{print $2}'`

CONVERTWPMODE=`date -d "$YEAR-$MONTH-$DAY"T"$TIME" "+%s"`

DIFWPMODE=`expr $TIMESTAMPWPMODE - $CONVERTWPMODE`

CHECKWPMODE=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXWPMODE" | grep \"Level\" | cut -d: -f2 | tr -d , | xargs`

if [ "$DIFWPMODE" -lt "60" ]; then
        echo "WP Mode Domoticz changed"

	 if [ "$CHECKWPMODE" == "10" ]; then
                 MELMODE=0
         fi
	 if [ "$CHECKWPMODE" == "20" ]; then
                 MELMODE=1
         fi
	 if [ "$CHECKWPMODE" == "30" ]; then
                 MELMODE=2
         fi
	 if [ "$CHECKWPMODE" == "40" ]; then
                 MELMODE=3
         fi
	 if [ "$CHECKWPMODE" == "50" ]; then
                 MELMODE=4
         fi
	 if [ "$CHECKWPMODE" == "60" ]; then
                 MELMODE=5
         fi


CMD="$CURL -s 'https://app.melcloud.com/Mitsubishi.Wifi.Client/Device/SetAtw' -H 'Pragma: no-cache' -H 'Origin: https://app.melcloud.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: nl-NL,nl;q=0.8,en-US;q=0.6,en;q=0.4,af;q=0.2,de;q=0.2,lt;q=0.2,es;q=0.2' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36' -H 'Content-Type: application/json; charset=UTF-8' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Cache-Control: no-cache' -H 'X-MitsContextKey: $KEY' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'Referer: https://app.melcloud.com/' --data-binary '{\"EffectiveFlags\":8,\"OperationMode\":0,\"OperationModeZone1\":$MELMODE,\"HCControlType\":1,\"UnitStatus\":0,\"TemperatureIncrementOverride\":\"2\",\"DeviceID\":$DEVICEID,\"DeviceType\":1,\"LastCommunication\":\"2016-10-26T13:57:46.917\",\"NextCommunication\":\"2016-10-26T13:58:46.917\",\"Power\":true,\"HasPendingCommand\":false,\"Offline\":false}' --compressed"

echo $CMD > $FOLDER/temp.sh
chmod +x $FOLDER/temp.sh
/$FOLDER/temp.sh

else

CHECKWPMODE=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXWPMODE" | grep \"Level\" | cut -d: -f2 | tr -d , | xargs`


if [ "$CHECKWPMODE" != "$OPMODEZ1" ]; then
	/bin/echo "Update Operation Mode"
        $CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXWPMODE&nvalue=1&svalue=$OPMODEZ1"
fi

fi



echo "Update SWW Temp"

SWWTEMP=`echo $DATA | $JSON "TankWaterTemperature"`
$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXSWWTEMP&nvalue=0&svalue=$SWWTEMP"

echo "Update SWW Setpoint"

SWWSETPOINT=`echo $DATA | $JSON "SetTankWaterTemperature"`
$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXSWWSETPOINT&nvalue=0&svalue=$SWWSETPOINT"


OPMODE=`echo $DATA | $JSON "OperationMode"`

CHECKWPSTATUS=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXWPSTATUS" | $GREP Data | $AWK '{print $3;}' | $SED 's/"//' | $TR -d ',' | $TR -d '"'`

if [ "$OPMODE" == "2" ]; then
        OPMODE="Heating"
		if [ "$CHECKWPSTATUS" != "$OPMODE" ]; then
			echo "Update Operation Modus to $OPMODE"
			 curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXWPSTATUS&nvalue=0&svalue=$OPMODE"
		fi

fi

if [ "$OPMODE" == "3" ]; then
        OPMODE="Cooling"
		if [ "$CHECKWPSTATUS" != "$OPMODE" ]; then
			echo "Update Operation Modus to $OPMODE"
			curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXWPSTATUS&nvalue=0&svalue=$OPMODE"
		fi
fi

if [ "$OPMODE" == "1" ]; then
        OPMODE="SWW"
		if [ "$CHECKWPSTATUS" != "$OPMODE" ]; then
			echo "Update Operation Modus to $OPMODE"
			curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXWPSTATUS&nvalue=0&svalue=$OPMODE"
		fi
fi

if [ "$OPMODE" == "0" ]; then
        OPMODE="Off"
		if [ "$CHECKWPSTATUS" != "$OPMODE" ]; then
			echo "Update Operation Modus to $OPMODE"
			curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXWPSTATUS&nvalue=0&svalue=$OPMODE"
		fi
fi

if [ "$OPMODE" == "5" ]; then
        OPMODE="Standby"
		if [ "$CHECKWPSTATUS" != "$OPMODE" ]; then
			echo "Update Operation Modus to $OPMODE"
			curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXWPSTATUS&nvalue=0&svalue=$OPMODE"
		fi
fi

if [ "$OPMODE" == "6" ]; then
        OPMODE="Legionella"
		if [ "$CHECKWPSTATUS" != "$OPMODE" ]; then
			echo "Update Operation Modus to $OPMODE"
			curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXWPSTATUS&nvalue=0&svalue=$OPMODE"
		fi
fi

CHECKWPACTIVE=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXWPACTIVE" | $GREP Data | $AWK '{print $3;}' | $SED 's/"//' | $TR -d ',' | $TR -d '"'`


if [ "$OPMODE" == "Off" ]; then
	if [ "$CHECKWPACTIVE" != "Off" ]; then
	/bin/echo "Update Operation Mode to Off"
        curl -s "http://$SERVERIP:$PORT/json.htm?type=command&param=switchlight&idx=$IDXWPACTIVE&switchcmd=Off"
	fi
else
	if [ "$CHECKWPACTIVE" != "On" ]; then
	/bin/echo "Update Operation Mode to On"
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


# Check when setpoint was changed at Domoticz

LASTUPDATE=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXSETPOINT" | $JSON | $GREP LastUpdate | cut -d\" -f4`
TIMESTAMP=$(date +%s)

DAY=`echo $LASTUPDATE | cut -d- -f3 | cut -d" " -f1`
MONTH=`echo $LASTUPDATE | cut -d- -f2`
YEAR=`echo $LASTUPDATE | cut -d- -f1`
TIME=`echo $LASTUPDATE | awk '{print $2}'`

CONVERT=`date -d "$YEAR-$MONTH-$DAY"T"$TIME" "+%s"`

DIF=`expr $TIMESTAMP - $CONVERT`

### Read setpoint from Json and send it to Domoticz

SETPOINT=`echo $DATA | $JSON "SetTemperatureZone1"`

CHECKSETPOINT=`$CURL -s "http://$SERVERIP:$PORT/json.htm?type=devices&rid=$IDXSETPOINT" | grep Data | awk '{print $3}' | tr -d ,\"`
CHECKSETPOINT="${CHECKSETPOINT%.0}"

SKIPSETPOINT=0

if [ "$DIF" -lt "60" ]; then
        echo "Setpoint Domoticz adjusted"
	MELSETPOINT=$CHECKSETPOINT		
	SKIPSETPOINT=1	
	MELCLOUDSEND=1

## Can be removed in final version
	
#SETMELCLOUDSETPOINT="$CURL -s 'https://app.melcloud.com/Mitsubishi.Wifi.Client/Device/SetAtw' -H 'X-MitsContextKey: $KEY' -H 'Origin: https://app.melcloud.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: nl-NL,nl;q=0.8,en-US;q=0.6,en;q=0.4,af;q=0.2,de;q=0.2,lt;q=0.2,es;q=0.2' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36' -H 'Content-Type: application/json; charset=UTF-8' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: https://app.melcloud.com/' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' --data-binary '{\"EffectiveFlags\":8589934720,\"LocalIPAddress\":null,\"SetTemperatureZone1\":\"$CHECKSETPOINT\",\"DeviceID\":$DEVICEID,\"DeviceType\":1,\"Power\":true,\"HasPendingCommand\":true,\"Offline\":false}' --compressed"

#echo $SETMELCLOUDSETPOINT > $FOLDER/temp.sh
#chmod +x $FOLDER/temp.sh
#$FOLDER/temp.sh > /dev/null
#exit

fi

if [ "$SKIPSETPOINT" != "1" ]; then
	
	if [ "$CHECKSETPOINT" != "$SETPOINT" ]; then
       		echo "Update Set Point"
       		$CURL -s "http://$SERVERIP:$PORT/json.htm?type=command&param=udevice&idx=$IDXSETPOINT&nvalue=0&svalue=$SETPOINT"
	fi

fi


## Create Melcloud command structure

if [ "$MELCLOUDSEND" == "1" ]; then

echo "Send setpoint to Melcloud"

CMD="curl -s 'https://app.melcloud.com/Mitsubishi.Wifi.Client/Device/SetAtw'
-H 'X-MitsContextKey: $KEY' \
-H 'Origin: https://app.melcloud.com' \
-H 'Accept-Encoding: gzip, deflate, br' \
-H 'Accept-Language: nl-NL,nl;q=0.8,en-US;q=0.6,en;q=0.4,af;q=0.2,de;q=0.2,lt;q=0.2,es;q=0.2' \
-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36' \
-H 'Content-Type: application/json; charset=UTF-8' \
-H 'Accept: application/json, text/javascript, */*; q=0.01' \
-H 'Referer: https://app.melcloud.com/' \
-H 'X-Requested-With: XMLHttpRequest' \
-H 'Connection: keep-alive' \
--data-binary '{ \
\"EffectiveFlags\":8589934720,\
\"SetTemperatureZone1\":$CHECKSETPOINT,\
\"DeviceID\":$DEVICEID,\
\"DeviceType\":1,\
\"HasPendingCommand\":true,\
\"Offline\":false}' \
--compressed"

echo $CMD > /$FOLDER/temp.melcloud.sh
chmod +x /$FOLDER/temp.melcloud.sh
/$FOLDER/temp.melcloud.sh > /dev/null

else

	echo "No Temp changes are send to Melcloud"
	exit
fi


if [ "$MELCLOUDSEND" == "2" ]; then

CMD="$CURL -s 'https://app.melcloud.com/Mitsubishi.Wifi.Client/Device/SetAtw' -H 'Pragma: no-cache' -H 'Origin: https://app.melcloud.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: nl-NL,nl;q=0.8,en-US;q=0.6,en;q=0.4,af;q=0.2,de;q=0.2,lt;q=0.2,es;q=0.2' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36' -H 'Content-Type: application/json; charset=UTF-8' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Cache-Control: no-cache' -H 'X-MitsContextKey: 0E92E43D4696427AB74324E01D16B7' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'Referer: https://app.melcloud.com/' --data-binary '{\"EffectiveFlags\":8,\"OperationMode\":0,\"OperationModeZone1\":$MELMODE,\"HCControlType\":1,\"UnitStatus\":0,\"TemperatureIncrementOverride\":\"2\",\"DeviceID\":63051,\"DeviceType\":1,\"LastCommunication\":\"2016-10-26T13:57:46.917\",\"NextCommunication\":\"2016-10-26T13:58:46.917\",\"Power\":true,\"HasPendingCommand\":false,\"Offline\":false}' --compressed"

echo $CMD > /$FOLDER/temp.sh
chmod +x /$FOLDER/temp.sh
/$FOLDER/temp.sh > /dev/null

else

	echo "No Mode changes are send to Melcloud"
	exit
fi

