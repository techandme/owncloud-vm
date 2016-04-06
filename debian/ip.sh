#!/bin/sh
IFACE="eth0"

IFCONFIG="/sbin/ifconfig"
IP="/sbin/ip"
INTERFACES="/etc/network/interfaces"

ADDRESS=$(ip route get 1 | awk '{print $NF;exit}')
NETMASK=$($IFCONFIG eth0 | grep Mask | sed s/^.*Mask://)
GATEWAY=$($IP route | awk '/default/ { print $3 }')

cat <<-IPCONFIG > "$INTERFACES"
        auto lo $IFACE

        iface lo inet loopback
                pre-up /sbin/ethtool -K $IFACE tso off
                pre-up /sbin/ethtool -K $IFACE gso off

        iface $IFACE inet static

                address $ADDRESS
                netmask $NETMASK
                gateway $GATEWAY

# Exit and save:	[CTRL+X] + [Y] + [ENTER]
# Exit without saving:	[CTRL+X]

IPCONFIG

exit 0
