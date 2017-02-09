#!/bin/bash
#
## Tech and Me ## - ©2017, https://www.techandme.se/
#
# Tested on Ubuntu Server 14.04.
#
SCRIPTS=/var/scripts
HTML=/var/www/html
OCPATH=$HTML/owncloud
DATA=$OCPATH/data
SECURE="$SCRIPTS/setup_secure_permissions_owncloud.sh"
THEME_NAME=""

# Must be root
[[ $(id -u) -eq 0 ]] || { echo "Must be root to run script, in Ubuntu type: sudo -i"; exit 1; }

# Set secure permissions
if [ -f $SECURE ];
then
        echo "Script exists"
else
        mkdir -p $SCRIPTS
        wget https://raw.githubusercontent.com/techandme/owncloud-vm/master/beta/setup_secure_permissions_owncloud.sh -P $SCRIPTS
    fi

# System Upgrade
sudo apt update -q2
sudo aptitude full-upgrade -y

# Backup data
clear 
echo "Backing up data and config files + theme..."
sleep 1
rsync -Aaxv $DATA $HTML
rsync -Aax $OCPATH/config $HTML
rsync -Aax $OCPATH/themes $HTML
if [[ $? > 0 ]]
then
    echo "Backup was not OK. Please check $HTML and see if the folders are backed up properly"
    exit
else
   echo "Backup OK!"
    fi

# Get new version of ownCloud.
	git --version 2>&1 >/dev/null
	GIT_IS_AVAILABLE=$?
# ...
if [ $GIT_IS_AVAILABLE -eq 1 ]; then
        sleep 1
else
        apt install git -y -q
    fi
if [ -d $OCPATH ]; 
then 
echo "$OCPATH will be deleted and replaced with the latest git clone of ownCloud core."
    fi
read -p "Are you sure? (Yy/Nn) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
echo
rm -rf $OCPATH
cd $HTML
git clone https://github.com/owncloud/core.git owncloud 
else
exit
    fi
if [[ $? > 0 ]]
then
    echo "Git Clone NOT OK"
    exit 1
else
   echo "Git Clone OK!"
    fi
# Check that $OCPATH exists, else abort.
if [ -d $OCPATH ];
then
        echo "/$OCPATH exists"
else
        echo "Aborting, $OCPATH does not exist."
   exit 1
    fi

# Check that everything is backed up properly
if [ -d $HTML/config/ ]; then
        echo "config/ exists" 
else
        echo "Something went wrong with backing up your old ownCloud instance, please check in $HTML if data/ and config/ folders exist."
   exit 1
    fi

if [ -d $HTML/themes/ ]; then
        echo "themes/ exists" 
else
        echo "Something went wrong with backing up your old ownCloud instance, please check in $HTML if data/ and config/ folders exist."
   exit 1
    fi

if [ -d $HTML/data ]; then
        echo "data/ exists" && sleep 3
        cp -R $HTML/themes $OCPATH/ && rm -rf $HTML/themes
        cp -R $HTML/data $DATA && rm -rf $HTML/data
        cp -R $HTML/config $OCPATH/ && rm -rf $HTML/config
        bash $SECURE
else
        echo "Something went wrong with backing up your old ownCloud instance, please check in $HTML if data/ and config/ folders exist in $HTML."
   exit 1
    fi

# Increase max filesize (expects that changes are made in Apache's php.ini)
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

# Cleanup un-used packages
sudo apt autoremove -y
sudo apt autoclean

# Update GRUB, just in case
sudo update-grub

# Write to log
touch /var/log/cronjobs_success.log
echo "OWNCLOUD UPDATE success-$(date +"%Y%m%d")" >> /var/log/cronjobs_success.log

# Set secure permissions again
bash $SECURE

## Un-hash this if you want the system to reboot
# sudo reboot

exit 0
