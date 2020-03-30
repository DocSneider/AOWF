#!/bin/bash
tty=/dev/ttyUSB0
exec 4<$tty 5>$tty # just found this sulution somewhere in the www, don´t really what it does
stty -F $tty 115200 -brkint -icrnl -imaxbel iutf8 -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke

tftp_client_ip="10.10.30.111"
tftp_server_ip="10.10.30.1"
tftp_file="test.file"

while [ "$firstword" != "Please" ]; do 
    read -e output <&4
    firstword=$(echo "$output" | cut -f1 -d" ")
    echo "$output"
done

#printf "\t\n  ***** ***** gotcha! ***** *****  \n\n"
sleep 0.5

# DONT SEND NEWLINE - otherwise uboot doesn´t recognize commands !!!!!

echo -n "1" >&5 # echo '1' for taking boot option 1
printf "\t\n ***** ***** echo '1' ***** ***** \n\n"
# MUST TO WAIT FOR DELAY - try to fix that by emulate RETURN button?
sleep 5

#input TFTP-client IP
for((i=0;i<20;i++)); do
    echo -ne "\b \b" >&5 #erase characters
    sleep 0.05
done
printf  "%s\r" "$tftp_client_ip" >&5

#input TFTP-server IP
for((i=0;i<20;i++)); do
    echo -ne "\b \b" >&5
    sleep 0.05
done
printf  "%s\r" "$tftp_server_ip" >&5

#input TFTP-file
printf  "%s\r" "$tftp_file" >&5

while true; do #just for debugging...
    read -e output <&4
    echo "$output"
done

#commands for setting Target-IP, TFTP-Server-IP-address should follow here... 