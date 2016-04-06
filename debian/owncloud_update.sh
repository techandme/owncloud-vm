#!/bin/bash
#
## Tech and Me ## - ©2016, https://www.techandme.se/
#
# Tested on Ubuntu Server 14.04.
#
export SCRIPTS=/var/scripts
export HTML=/var/www/html
export OCPATH=$HTML/owncloud
export DATA=$OCPATH/data
export SECURE="$SCRIPTS/setup_secure_permissions_owncloud.sh"
export THEME_NAME=""

# Must be root
[[ $(id -u) -eq 0 ]] || { echo -e "\e[31mSorry, you are not root.\n\e[0mYou must type: \e[36msu root -c 'bash $SCRIPTS/owncloud_update.sh'"; exit 1; }

# Set secure permissions
if [ -f $SECURE ];
then
        echo "Script exists"
else
        mkdir -p $SCRIPTS
        wget https://raw.githubusercontent.com/enoch85/ownCloud-VM/master/debian/setup_secure_permissions_owncloud.sh -P $SCRIPTS
fi

# System Upgrade
aptitude update
aptitude full-upgrade -y

# Enable maintenance mode
su -s /bin/sh -c 'php $OCPATH/occ maintenance:mode --on' www-data

# Backup data
rsync -Aaxv $DATA $HTML
rsync -Aax $OCPATH/config $HTML
rsync -Aax $OCPATH/themes $HTML
rsync -Aax $OCPATH/apps $HTML
if [[ $? > 0 ]]
then
    echo "Backup was not OK. Please check $HTML and see if the folders are backed up properly"
    exit
else
		echo -e "\e[32m"
    echo "Backup OK!"
    echo -e "\e[0m"
fi
wget https://download.owncloud.org/community/owncloud-latest.tar.bz2 -P $HTML

if [ -f $HTML/owncloud-latest.tar.bz2 ];
then
        echo "$HTML/owncloud-latest.tar.bz2 exists"
else
        echo "Aborting,something went wrong with the download"
   exit 1
fi

if [ -d $OCPATH/config/ ]; then
        echo "config/ exists" 
else
        echo "Something went wrong with backing up your old ownCloud instance, please check in $HTML if data/ and config/ folders exist."
   exit 1
fi

if [ -d $OCPATH/themes/ ]; then
        echo "themes/ exists" 
else
        echo "Something went wrong with backing up your old ownCloud instance, please check in $HTML if data/ and config/ folders exist."
   exit 1
fi

if [ -d $OCPATH/apps/ ]; then
        echo "apps/ exists" 
else
        echo "Something went wrong with backing up your old ownCloud instance, please check in $HTML if data/ and config/ folders exist."
   exit 1
fi

if [ -d $DATA/ ]; then
        echo "data/ exists" && sleep 2
        rm -rf $OCPATH
        tar -xjf $HTML/owncloud-latest.tar.bz2 -C $HTML 
        rm $HTML/owncloud-latest.tar.bz2
        cp -R $HTML/themes $OCPATH/ && rm -rf $HTML/themes
        cp -Rv $HTML/data $DATA && rm -rf $HTML/data
        cp -R $HTML/config $OCPATH/ && rm -rf $HTML/config
        cp -R $HTML/apps $OCPATH/ && rm -rf $HTML/apps
        bash $SECURE
        su -s /bin/sh -c 'php $OCPATH/occ maintenance:mode --off' www-data
        su -s /bin/sh -c 'php $OCPATH/occ upgrade' www-data
else
        echo "Something went wrong with backing up your old ownCloud instance, please check in $HTML if data/ and config/ folders exist."
   exit 1
fi

# Enable Apps
su -s /bin/sh -c 'php $OCPATH/occ app:enable calendar' www-data
su -s /bin/sh -c 'php $OCPATH/occ app:enable contacts' www-data
su -s /bin/sh -c 'php $OCPATH/occ app:enable documents' www-data
su -s /bin/sh -c 'php $OCPATH/occ app:enable external' www-data

# Second run (to make sure everything is updated, somtimes apps needs a second run)
su -s /bin/sh -c 'php $OCPATH/occ upgrade' www-data
# Enable Apps
su -s /bin/sh -c 'php $OCPATH/occ app:enable calendar' www-data
su -s /bin/sh -c 'php $OCPATH/occ app:enable contacts' www-data
su -s /bin/sh -c 'php $OCPATH/occ app:enable documents' www-data
su -s /bin/sh -c 'php $OCPATH/occ app:enable external' www-data

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

# Repair
su -s /bin/sh -c 'php $OCPATH/occ maintenance:repair' www-data

# Cleanup un-used packages
aptitude autoclean

# Update GRUB, just in case
update-grub

# Write to log
touch /var/log/cronjobs_success.log
echo "OWNCLOUD UPDATE success-$(date +"%Y%m%d")" >> /var/log/cronjobs_success.log
echo
echo ownCloud version:
su -s /bin/sh -c 'php $OCPATH/occ status' www-data
echo
echo
sleep 3

# Set secure permissions again
bash $SECURE

## Un-hash this if you want the system to reboot
# reboot

unset SCRIPTS
unset HTML
unset OCPATH
unset DATA
unset SECURE
unset THEME_NAME

exit 0
