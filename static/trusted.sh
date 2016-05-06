#!/bin/bash

HTML=/var/www
OCPATH=$HTML/owncloud
ADDRESS=$(hostname -I | cut -d ' ' -f 1)
SCRIPTS=/var/scripts

# Change config.php
php $SCRIPTS/update-config.php $OCPATH/config/config.php 'trusted_domains[]' localhost ${ADDRESS[@]} $(hostname) $(hostname --fqdn) 2>&1 >/dev/null
php $SCRIPTS/update-config.php $OCPATH/config/config.php overwrite.cli.url https://$ADDRESS/ 2>&1 >/dev/null

# Change .htaccess accordingly
sed -i "s|RewriteBase /owncloud|RewriteBase /|g" /var/www/owncloud/.htaccess

exit 0
