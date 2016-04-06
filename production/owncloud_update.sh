#!/bin/bash
#
## Tech and Me ## - ©2016, https://www.techandme.se/
#
# Tested on Ubuntu Server 14.04.
#

THEME_NAME=""
STATIC="https://raw.githubusercontent.com/enoch85/ownCloud-VM/master/static"
SCRIPTS=/var/scripts
OCPATH=/var/www/owncloud

# Must be root
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script, in Ubuntu type: sudo -i"; exit 1; }

# System Upgrade
sudo apt-get update
sudo aptitude full-upgrade -y
sudo -u www-data php $OCPATH/occ upgrade

# Enable Apps
sudo -u www-data php $OCPATH/occ app:enable calendar
sudo -u www-data php $OCPATH/occ app:enable contacts
sudo -u www-data php $OCPATH/occ app:enable documents
sudo -u www-data php $OCPATH/occ app:enable external

# Disable maintenance mode
sudo -u www-data php $OCPATH/occ maintenance:mode --off

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
sudo bash $SCRIPTS/setup_secure_permissions_owncloud.sh

# Repair
sudo -u www-data php $OCPATH/occ maintenance:repair

# Cleanup un-used packages
sudo apt-get autoremove -y
sudo apt-get autoclean

# Update GRUB, just in case
sudo update-grub

# Write to log
touch /var/log/cronjobs_success.log
echo "OWNCLOUD UPDATE success-`date +"%Y%m%d"`" >> /var/log/cronjobs_success.log
echo
echo ownCloud version:
sudo -u www-data php $OCPATH/occ status
echo
echo

## Un-hash this if you want the system to reboot
# sudo reboot

exit 0
