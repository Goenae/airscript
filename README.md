Goal of the script:
Airscript is using Aircrack to automatically make a Rogue AP, it will:
-Scan APs and dectect the most used one
-Replicate this AP and deauthenticate clients using it to lead them to the attacker AP
-Sniff the trafic

How to use it:
./airscript.sh <interface> <monitor_interface>
Channel can also be specified in the source code (default is 11)
