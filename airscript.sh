#!/bin/bash

interface="$1"

clear

sudo airmon-ng check kill

sudo timeout -s 2 15 airodump-ng wlan0mon -w psk & echo "DEBUG" & sleep 16

sudo rm psk-01.cap & sudo rm psk-01.csv & sudo rm psk-01.kismet.netxml

maxData=0
finalName=""
finalSSID=""

input="psk-01.kismet.csv"
#Delete first line of the file (without data)
sed -i '1d' $input
#Read each line
while IFS= read -r line
do
  #Parse the given line and put every datas in an array
  IFS=';' read -ra ARRAY <<< "$line"

  if [ "${ARRAY[13]}" -gt "$maxData" ] ; then
    maxData="${ARRAY[13]}"
    finalName="${ARRAY[2]}"
    finalSSID="${ARRAY[3]}"

  fi


done < "$input"

echo "$maxData"
echo "$finalName"
echo "$finalSSID"
