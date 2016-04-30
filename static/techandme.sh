#!/bin/bash
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
ADDRESS=$(hostname -I | cut -d ' ' -f 1)
clear
figlet -f small Tech and Me
echo "           https://www.techandme.se"
echo
echo
echo
echo "WAN IP: $WANIP"
echo "LAN IP: $ADDRESS"
echo
exit 0
