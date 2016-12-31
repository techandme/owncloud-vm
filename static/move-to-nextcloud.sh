#!/bin/bash

# This script is written by Tech and Me 2017.
# The purpose of this script is to migrate from ownCloud to Nextcloud.
# We expect you to run our ownCloud VM. This script may not work with every installation.
# But if you have your datafolder outside ownCloud root then you are safe.
# Though we do also check if you have your data in the regular path which is /var/www/owncloud/data.

# ownCloud MySQL database name
OCDB=owncloud_db
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
echo "# We expect you to run our ownCloud VM. This script may not work with other installations,"
echo "# but if you have your datafolder outside ownCloud root then you are safe."
echo "# Though we do also check if you have your data in the regular path which is $OCPATH/data."
echo "# We will backup your ownCloud config files + MySQL + data in $BACKUP"
echo "# Please also check that both the Apache Vhost and the name of the DB are correct before you run this script."
echo "# Right now the Vhost are; $VHOST and the DB name are; $OCDB"
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

# Backup ownCloud config + data + MySQL
echo "Backing up config...."
# Config
rsync -Aaxt $OCPATH/config $BACKUP
if [[ $? == 0 ]]
then
    echo -e "\e[32mSUCCESS!\e[0m"
else
    echo "Backup failed"
    exit 1
fi
# MySQL
PW_FILE=/var/mysql_password.txt
OLDMYSQL=$(cat $PW_FILE)
echo "Backing up MySQL..."
if [ -f $PW_FILE ]
then
    sleep 1
else
   echo "You have to put your root MySQL password in $PW_FILE for this script to work"
   exit 1
fi
mkdir -p $BACKUP/mysql
mysqldump -u root -p$OLDMYSQL --databases $OCDB > $BACKUP/mysql/$OCDB.sql
mysqldump -u root -p$OLDMYSQL --all-databases > $BACKUP/mysql/all-databases.sql
if [ $? -eq 0 ]
then
        echo -e "\e[32mSUCCESS!\e[0m"
        echo "Your MySQL + config files are stored in $BACKUP"
else
        echo "Backing up MySQL failed."
        exit 1
fi
# Data
echo "Backing up $OCPATH/data...."
files=$(shopt -s nullglob dotglob; echo $OCPATH/data/*)
if (( ${#files} ))
then
    rsync -Aaxt $OCPATH/data $BACKUP
    echo "$OCPATH/data is stored in $BACKUP"
else
    echo
    echo "Your datafolder doesn't seem to be in $OCPATH/data"
    echo "If you have your data outside of $OCPATH then you're safe."
    echo "We will remove $OCPATH completley when this script is done."
    echo -e "\e[32m"
    read -p "Press any key to continue the migration, or press CTRL+C to abort..." -n1 -s
    echo -e "\e[0m"
fi

# Get the latest Nextcloud release and exctract
wget $NCREPO/nextcloud-$NCVERSION.tar.bz2 -P $HTML
tar -xjf $NCPATH-$NCVERSION.tar.bz2 -C $HTML

# Restore Backup
cp -R $BACKUP/* $NCPATH/
rm -R $NCPATH/mysql

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
    sudo -u www-data php $NCPATH/occ maintenance:mode --off
    echo -e "\e[32m"
    echo "Migration success! Please check that everything is in order"
    echo
    read -p "Press any key to remove $OCPATH..." -n1 -s
    echo -e "\e[0m"
    rm -R $OCPATH
    cd /
    apt purge owncloud* -y
    apt autoremove -y
    rm /etc/apt/sources.list.d/owncloud.list
    rm $SCRIPTS/owncloud_update.sh
    rm $SCRIPTS/update.sh
    wget -q https://raw.githubusercontent.com/nextcloud/vm/master/static/update.sh
    service apache2 restart
    crontab -u www-data -r
    crontab -u www-data -l | { cat; echo "*/15  *  *  *  * php -f $NCPATH/cron.php > /dev/null 2>&1"; } | crontab -u www-data -
    # Install PHP 7.0
    echo "Re-installing PHP 7..."
    apt update -q2
    apt install -y \
        libapache2-mod-php7.0 \
        php7.0-common \
        php7.0-mysql \
        php7.0-intl \
        php7.0-mcrypt \
        php7.0-ldap \
        php7.0-imap \
        php7.0-cli \
        php7.0-gd \
        php7.0-pgsql \
        php7.0-json \
        php7.0-sqlite3 \
        php7.0-curl \
        php7.0-xml \
        php7.0-zip \
        php7.0-mbstring \
        php-smbclient
    service apache2 restart
    echo
    echo "Your backup is still available at $BACKUP"
    echo "Apps are deactivated, please login to Nextcloud and reactivate them."
    echo "Thank you for using Tech and Me!"
    exit 0
else
    echo "Migration failed! But don't worry, your config is still intact and we have not removed your ownCloud folder"
    exit 1
fi
