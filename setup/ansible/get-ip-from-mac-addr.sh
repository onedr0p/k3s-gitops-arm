#!/bin/bash

mac_addresses=(dc:a6:32:00:81:c6 dc:a6:32:05:1a:09 dc:a6:32:05:32:72 dc:a6:32:04:b0:fd dc:a6:32:03:d2:ff dc:a6:32:03:cf:77)

for mac_address in "${mac_addresses[@]}"  
do
    ip=$(sudo arp-scan -l | grep "${mac_address}" | awk '{print $1}')
    echo "mac address ${mac_address} is a registered to ip ${ip}"
done