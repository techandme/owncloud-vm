#!/bin/bash
#
## Tech and Me ## - ©2017, https://www.techandme.se/
#

export SCRIPTS=/var/scripts
export PW_FILE=/var/M-R_passwords.txt # Keep in sync with owncloud_install.sh
export CLEARBOOT=$(dpkg -l linux-* | awk '/^ii/{ print $2}' | grep -v -e `uname -r | cut -f1,2 -d"-"` | grep -e [0-9] | xargs sudo aptitude-y purge)
export IP="/sbin/ip"
export IFACE=$($IP -o link show | awk '{print $2,$9}' | grep "UP" | cut -d ":" -f 1)
export IFCONFIG="/sbin/ifconfig"
export ADDRESS=$(hostname -I | cut -d ' ' -f 1)
export OCDATA=/var/ocdata
export HTML=/var/www
export OCPATH=$HTML/owncloud

# Check if root
if [ "$(whoami)" != "root" ]; then
        echo
        echo -e "\e[31mSorry, you are not root.\n\e[0mYou must type: \e[36msu root -c 'bash $SCRIPTS/owncloud-startup-script.sh'"
        echo
        exit 1
fi
clear
echo "+--------------------------------------------------------------------+"
echo "| This script will configure your ownCloud and activate SSL.         |"
echo "| It will also do the following:                                     |"
echo "|                                                                    |"
echo "| - Install Webmin                                                   |"
echo "| - Install Redis Cache                                              |"
echo "| - Upgrade your system to latest version                            |"
echo "| - Set new passwords to UNIX (ocadmin) and ownCloud                 |"
echo "| - Set new keyboard layout                                          |"
echo "| - Change timezone                                                  |"
echo "| - Set static IP to the system (you have to set the same IP in      |"
echo "|   your router) https://www.techandme.se/open-port-80-443/          |"
echo "|                                                                    |"
echo "|   The script will take about 10 minutes to finish,                 |"
echo "|   depending on your internet connection.                           |"
echo "|                                                                    |"
echo "| ####################### Tech and Me - 2017 ####################### |"
echo "+--------------------------------------------------------------------+"
echo -e "\e[32m"
read -p "Press any key to start the script..." -n1 -s
clear
echo -e "\e[0m"

# Change IP
echo -e "\e[0m"
echo "The script will now configure your IP to be static."
echo -e "\e[36m"
echo -e "\e[1m"
echo "Your internal IP is: $ADDRESS"
echo -e "\e[0m"
echo -e "Write this down, you will need it to set static IP"
echo -e "in your router later. It's included in this guide:"
echo -e "https://www.techandme.se/open-port-80-443/ (step 1 - 5)"
echo -e "\e[32m"
read -p "Press any key to set static IP..." -n1 -s
clear
echo -e "\e[0m"
ifdown $IFACE
sleep 2
ifup $IFACE
sleep 2
bash $SCRIPTS/ip.sh
sed -i "s|pre-up|#pre-up|g" /etc/network/interfaces

ifdown $IFACE
sleep 2
ifup $IFACE
sleep 2
echo
echo "Testing if network is OK..."
sleep 1
echo
bash $SCRIPTS/test_connection.sh
sleep 2
echo
echo -e "\e[0mIf the output is \e[32mConnected! \o/\e[0m everything is working."
echo -e "\e[0mIf the output is \e[31mNot Connected!\e[0m you should change\nyour settings manually in the next step."
echo -e "\e[32m"
read -p "Press any key to open /etc/network/interfaces..." -n1 -s
echo -e "\e[0m"
nano /etc/network/interfaces
clear &&
echo "Testing if network is OK..."
ifdown $IFACE
sleep 2
ifup $IFACE
sleep 2
echo
bash $SCRIPTS/test_connection.sh
sleep 2
clear

# Change Trusted Domain and CLI
bash $SCRIPTS/trusted.sh

# Install packages for Webmin
aptitude install-y zip perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python

# Install Webmin
sed -i '$a deb http://download.webmin.com/download/repository sarge contrib' /etc/apt/sources.list
wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -
aptitude update
aptitude install-y webmin
echo
echo "Webmin is installed, access it from your browser: https://$ADDRESS:10000"
sleep 2
clear

# Set keyboard layout
echo "Current keyboard layout is Swedish"
echo "You must change keyboard layout to your language"
echo -e "\e[32m"
read -p "Press any key to change keyboard layout... " -n1 -s
echo -e "\e[0m"
dpkg-reconfigure keyboard-configuration
echo
clear

# Change Timezone
echo "Current Timezone is Europe/Stockholm"
echo "You must change timezone to your timezone"
echo -e "\e[32m"
read -p "Press any key to change timezone... " -n1 -s
echo -e "\e[0m"
dpkg-reconfigure tzdata
echo
sleep 3
clear

# Change password
echo -e "\e[0m"
echo "For better security, change the Linux password for [ocadmin]"
echo "The current password is [owncloud]"
echo -e "\e[32m"
read -p "Press any key to change password for Linux... " -n1 -s
echo -e "\e[0m"
    passwd ocadmin
if [[ $? > 0 ]]
then
    passwd ocadmin
else
    sleep 2
fi
echo
clear &&
echo -e "\e[0m"
echo "For better security, change the ownCloud password for [ocadmin]"
echo "The current password is [owncloud]"
echo -e "\e[32m"
read -p "Press any key to change password for ownCloud... " -n1 -s
echo -e "\e[0m"
su -s /bin/sh -c 'php $OCPATH/occ user:resetpassword ocadmin' www-data
if [[ $? > 0 ]]
then
    su -s /bin/sh -c 'php $OCPATH/occ user:resetpassword ocadmin' www-data
else
    sleep 2
fi

clear
echo
echo "The MySQL & ROOT passwords are:"
echo -e "\e[1m"
cat $PW_FILE
echo -e "\e[0m"
echo "Please note that this will not change, this is your last chance to save it!"
echo -e "\e[32m"
read -p "Press any key to continue... " -n1 -s
echo -e "\e[0m"

# Get the latest active-ssl script
        cd $SCRIPTS
        rm $SCRIPTS/activate-ssl.sh
        wget -q https://raw.githubusercontent.com/techandme/owncloud-vm/master/lets-encrypt/activate-ssl.sh
        chmod 755 $SCRIPTS/activate-ssl.sh
clear

# Install Redis
bash $SCRIPTS/install-redis-php-7.sh

# Upgrade system
clear
echo System will now upgrade...
sleep 2
echo
echo
bash $SCRIPTS/owncloud_update.sh

# Cleanup 1
aptitude autoclean
echo "$CLEARBOOT"
clear

# Change 000-default to $WEB_ROOT
sed -i "s|DocumentRoot /var/www/html|DocumentRoot $HTML|g" /etc/apache2/sites-available/000-default.conf

ADDRESS2=$(grep "address" /etc/network/interfaces | awk '$1 == "address" { print $2 }')
# Success!
echo -e "\e[32m"
echo    "+--------------------------------------------------------------------+"
echo    "| 	Congratulations! You have sucessfully installed ownCloud!     |"
echo    "|                                                                    |"
echo -e "|         \e[0mLogin to ownCloud in your browser:\e[36m" $ADDRESS2"\e[32m           |"
echo    "|                                                                    |"
echo -e "|         \e[0mPublish your server online! \e[36mhttps://goo.gl/iUGE2U\e[32m          |"
echo    "|                                                                    |"
echo -e "|      \e[0mMySQL & ROOT passwords are stored in: \e[36m$PW_FILE\e[32m  |"
echo    "|                                                                    |"
echo -e "|\e[91m####################### Tech and Me - 2017 #########################\e[32m|"
echo    "+--------------------------------------------------------------------+"
echo
read -p "Press any key to continue..." -n1 -s
echo -e "\e[0m"
echo

# Cleanup 2
su -s /bin/sh -c 'php $OCPATH/occ maintenance:repair' www-data
rm $SCRIPTS/ip*
rm $SCRIPTS/test_connection*
rm $SCRIPTS/change-ocadmin-profile*
rm $SCRIPTS/change-root-profile*
rm $SCRIPTS/install-redis-php-7*
rm $SCRIPTS/update-config*
rm $SCRIPTS/owncloud_install*
rm $SCRIPTS/trusted*
rm $SCRIPTS/owncloud-startup-script*
rm $OCDATA/owncloud.log*
sed -i "s|instruction.sh|techandme.sh|g" /home/ocadmin/.profile
cat /dev/null > ~/.bash_history
cat /dev/null > /var/spool/mail/root
cat /dev/null > /var/spool/mail/ocadmin
cat /dev/null > /var/log/apache2/access.log
cat /dev/null > /var/log/apache2/error.log
cat /dev/null > /var/log/cronjobs_success.log
sed -i 's/su -l root//g' /home/ocadmin/.profile
cat << RCLOCAL > "/etc/rc.local"
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0

RCLOCAL

clear
echo
echo
cat << LETSENC
+-----------------------------------------------+
|  Ok, now the last part - a proper SSL cert.   |
|                                               |
|  The following script will install a trusted 	|
|  SSL certificate through Let's encrypt.       |
+-----------------------------------------------+
LETSENC

# Let's Encrypt
function ask_yes_or_no() {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}
if [[ "yes" == $(ask_yes_or_no "Do you want to install SSL?") ]]
then
        bash $SCRIPTS/activate-ssl.sh
else
echo
    echo "OK, but if you want to run it later, just type: bash $SCRIPTS/activate-ssl.sh"
    echo -e "\e[32m"
    read -p "Press any key to continue... " -n1 -s
    echo -e "\e[0m"
fi

unset SCRIPTS
unset PW_FILE
unset CLEARBOOT
unset IFACE
unset IFCONFIG
unset ADDRESS
unset OCDATA
unset IP
unset OCPATH
unset HTML

# Reboot
reboot

exit 0
