#!/bin/bash

HTML=/var/www
OCPATH=$HTML/owncloud
IP="/sbin/ip"
IFACE=$($IP -o link show | awk '{print $2,$9}' | grep "UP" | cut -d ":" -f 1)
ADDRESS=$(hostname -I | cut -d ' ' -f 1)
SCRIPTS=/var/scripts

php $SCRIPTS/update-config.php $OCPATH/config/config.php 'trusted_domains[]' localhost ${ADDRESS[@]} $(hostname) $(hostname --fqdn) 2>&1 >/dev/null
php $SCRIPTS/update-config.php $OCPATH/config/config.php overwrite.cli.url https://$ADDRESS/owncloud 2>&1 >/dev/null

exit 0
