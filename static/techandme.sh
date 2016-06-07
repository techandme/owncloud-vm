#!/bin/bash
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
WANIP6=$(curl -s https://6.ifcfg.me/)
ADDRESS=$(hostname -I | cut -d ' ' -f 1)
clear
figlet -f small Tech and Me
echo "           https://www.techandme.se"
echo
echo
echo
echo "WAN IPv4: $WANIP"
echo "WAN IPv6: $WAN6"
echo "LAN IP: $ADDRESS"
echo
exit 0
