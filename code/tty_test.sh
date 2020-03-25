#!/bin/bash
tty=/dev/ttyUSB0
exec 4<$tty 5>$tty # just found this sulution somewhere in the www, don´t really what it does
stty -F $tty 115200 -echo

while [ "${output}" != "Please choose the operation:" ]; do 
    read output <&4 
    echo "$output"
done
printf "\t\n  ***** ***** gotcha! ***** *****  \n\n"

echo -e "\x31" >&5 # echo '1' for taking boot option 1
printf "\t\n ***** ***** echo '1' ***** ***** \n\n"

while true; do #just for debugging...
    read output <&4
    echo "$output"
done

#commands for setting Target-IP, TFTP-Server-IP-address should follow here... 