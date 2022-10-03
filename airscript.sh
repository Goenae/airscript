interface="$1"
sudo airodump-ng -w scan --output-format csv $interface
PID= pidof airodump-ng
second_pid= pidof airodump-ng | awk -F ' ' '{print $2}'
#sudo airodump-ng $interface -w psk
sleep 10
kill $second_pid
#pkill airodump-ng
