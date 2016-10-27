#!/bin/bash

# This script is written by Tech and Me 2016.
# The purpose of this script is to migrate from ownCloud to Nextcloud.
# We expect you you run our ownCloud VM. This script may not work with every installation.
# But if you have your datafolder outside ownCloud root then you are safe.
# Though we do also check if you have your data in the regular path which is /var/www/owncloud/data.

# Apache2 vhost
VHOST=owncloud_ssl_domain_self_signed.conf
# Directories
HTML=/var/www
NCPATH=$HTML/nextcloud
OCPATH=$HTML/owncloud
BACKUP=/var/OCBACKUP
SCRIPTS=/var/scripts
#Static Values
STATIC="https://raw.githubusercontent.com/nextcloud/vm/master/static"
NCREPO="https://download.nextcloud.com/server/releases"
SECURE="$SCRIPTS/setup_secure_permissions_nextcloud.sh"
GITHUB_REPO="https://raw.githubusercontent.com/nextcloud/vm/master"
# Version
NCVERSION=$(curl -s $NCREPO/ | tac | grep unknown.gif | sed 's/.*"nextcloud-\([^"]*\).zip.sha512".*/\1/;q')

# Must be root
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script, in Ubuntu type: sudo -i"; exit 1; }

echo
echo "# The purpose of this script is to migrate from ownCloud to Nextcloud."
echo "# We expect you you run our ownCloud VM. This script may not work with other installations,"
echo "# but if you have your datafolder outside ownCloud root then you are safe."
echo "# Though we do also check if you have your data in the regular path which is $OCPATH/data."
echo "# Please also check this script and change the $VHOST to your host before you run this script."
echo -e "\e[32m"
read -p "Press any key to continue the migration, or press CTRL+C to abort..." -n1 -s
clear
echo -e "\e[0m"

# Set secure permissions
FILE="$SECURE"
if [ -f $FILE ]
then
    echo "Script exists"
else
    mkdir -p $SCRIPTS
    wget -q $STATIC/setup_secure_permissions_nextcloud.sh -P $SCRIPTS
    chmod +x $SECURE
fi

# Put ownCloud in maintenance mode
sudo -u www-data php $OCPATH/occ maintenance:mode --on

# Backup ownCloud config + data
echo "Backing up config + data..."
rsync -Aaxt $OCPATH/config $BACKUP
if [ -d $OCPATH/data ]
then
    rsync -Aaxt $OCPATH/data $BACKUP
else
    echo "Your datafolder doesn't seem to be in $OCPATH/data"
    echo "We will remove $OCPATH completley when this script is done."
    echo "If you have your data outside of $OCPATH then you're safe."
    echo -e "\e[32m"
    read -p "Press any key to continue the migration, or press CTRL+C to abort..." -n1 -s
    echo -e "\e[0m"
fi

# Get the latest Nextcloud release and exctract
wget $NCREPO/nextcloud-$NCVERSION.tar.bz2 -P $HTML
tar -xjf $NCPATH-$NCVERSION.tar.bz2 -C $HTML

# Restore Backup
cp -R $BACKUP/* $NCPATH/

# Replace owncloud with nextcloud in $VHOST
a2dissite $VHOST
sed -i "s|owncloud|nextcloud|g" /etc/apache2/sites-available/$VHOST
a2ensite $VHOST
apachectl configtest
if [[ $? == 0 ]]
then
    service apache2 restart
else
    echo "Something went wrong with activating your new host. Please check /etc/apache2/sites-available/$VHOST that everything is correct."
    exit 1
fi

# Get the Welcome Screen when http://$address
if [ -f $SCRIPTS/index.php ]
then
    rm $SCRIPTS/index.php
    wget -q $GITHUB_REPO/index.php -P $SCRIPTS
else
    wget -q $GITHUB_REPO/index.php -P $SCRIPTS
fi
mv $SCRIPTS/index.php $HTML/index.php
chmod 750 $HTML/index.php && chown www-data:www-data $HTML/index.php

# Set Secure permissions
sudo bash $SCRIPTS/setup_secure_permissions_nextcloud.sh

# Upgrade to Nextcloud
sudo -u www-data php $NCPATH/occ upgrade
if [[ $? == 0 ]]
then
    sudo -u www-data php $OCPATH/occ maintenance:mode --off
    echo -e "\e[32m"
    echo "Migration success! Please check that everything is in order"
    echo
    read -p "Press any key to remove $OCPATH..." -n1 -s
    clear
    echo -e "\e[0m"
    rm -R $OCPATH
    apt-get purge owncloud* -y
    echo
    echo "Your backup is still available at $BACKUP"
    exit 0
else
    echo "Migration failed! But don't worry, your config is still intact and we have not removed your ownCloud folder"
    exit 1
fi
