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
echo "There is a bug in the ownCloud Core that breaks the password change with the occ command during setup."
echo "This will hopefully be fixed in 9.0.2, please have patience and thank you for understanding."
exit 0
