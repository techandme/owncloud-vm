#!/bin/bash
#
## Tech and Me ## - ©2017, https://www.techandme.se/
#
# Tested on Ubuntu Server 14.04.
#

export THEME_NAME=""
export STATIC="https://raw.githubusercontent.com/techandme/owncloud-vm/master/static"
export SCRIPTS=/var/scripts
export OCPATH=/var/www/owncloud

# Must be root
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script, in Ubuntu type: sudo -i"; exit 1; }

# System Upgrade
aptitude update
aptitude full-upgrade-y
su -s /bin/sh -c 'php $OCPATH/occ upgrade' www-data

# Enable Apps
su -s /bin/sh -c 'php $OCPATH/occ app:enable calendar' www-data
su -s /bin/sh -c 'php $OCPATH/occ app:enable contacts' www-data
su -s /bin/sh -c 'php $OCPATH/occ app:enable documents' www-data

# Disable maintenance mode
su -s /bin/sh -c 'php $OCPATH/occ maintenance:mode --off' www-data

# Increase max filesize (expects that changes are made in /etc/php5/apache2/php.ini)
# Here is a guide: https://www.techandme.se/increase-max-file-size/
VALUE="# php_value upload_max_filesize 513M"
if grep -Fxq "$VALUE" $OCPATH/.htaccess
then
        echo "Value correct"
else
        sed -i 's/  php_value upload_max_filesize 513M/# php_value upload_max_filesize 513M/g' $OCPATH/.htaccess
        sed -i 's/  php_value post_max_size 513M/# php_value post_max_size 513M/g' $OCPATH/.htaccess
        sed -i 's/  php_value memory_limit 512M/# php_value memory_limit 512M/g' $OCPATH/.htaccess
fi

# Set $THEME_NAME
VALUE2="$THEME_NAME"
if grep -Fxq "$VALUE2" $OCPATH/config/config.php
then
        echo "Theme correct"
else
        sed -i "s|'theme' => '',|'theme' => '$THEME_NAME',|g" $OCPATH/config/config.php
	echo "Theme set"
fi

# Set secure permissions
FILE="$SCRIPTS/setup_secure_permissions_owncloud.sh"
if [ -f $FILE ];
then
        echo "Script exists"
else
        mkdir -p $SCRIPTS
        wget -q $STATIC/setup_secure_permissions_owncloud.sh -P $SCRIPTS
	chmod +x $SCRIPTS/setup_secure_permissions_owncloud.sh
fi
bash $SCRIPTS/setup_secure_permissions_owncloud.sh

# Repair
su -s /bin/sh -c 'php $OCPATH/occ maintenance:repair' www-data

# Cleanup un-used packages
aptitude autoclean

# Update GRUB, just in case
update-grub

# Write to log
touch /var/log/cronjobs_success.log
echo "OWNCLOUD UPDATE success-`date +"%Y%m%d"`" >> /var/log/cronjobs_success.log
echo
echo ownCloud version:
su -s /bin/sh -c 'php $OCPATH/occ status' www-data
echo
echo

## Un-hash this if you want the system to reboot
# reboot

unset STATIC
unset SCRIPTS
unset THEME_NAME
unset OCPATH

exit 0
