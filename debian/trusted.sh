#!/bin/bash

HTML=/var/www/html
OCPATH=$HTML/owncloud
ADDRESS=$(ip route get 1 | awk '{print $NF;exit}')
SCRIPTS=/var/scripts

php $SCRIPTS/update-config.php $OCPATH/config/config.php 'trusted_domains[]' localhost ${ADDRESS[@]} $(hostname) $(hostname --fqdn) 2>&1 >/dev/null
php $SCRIPTS/update-config.php $OCPATH/config/config.php overwrite.cli.url https://$ADDRESS/owncloud 2>&1 >/dev/null

exit 0
