#!/bin/bash

# Tech and Me, ©2017 - www.techandme.se
#
# This install from ownCloud repos with PHP 7, MySQL 5.6 and Apache 2.4.

## THIS IS FOR TESTING ##

# Check for errors + debug code and abort if something isn't right
# 1 = ON
# 0 = OFF
DEBUG=0

# ownCloud version
OCVERSION=9.1.4RC2
# Ubuntu version
OS=$(grep -ic "Ubuntu" /etc/issue.net)
# Passwords
SHUF=$(shuf -i 13-15 -n 1)
MYSQL_PASS=$(cat /dev/urandom | tr -dc "a-zA-Z0-9@#*=" | fold -w $SHUF | head -n 1)
PW_FILE=/var/mysql_password.txt
# Directories
SCRIPTS=/var/scripts
HTML=/var/www
OCPATH=$HTML/owncloud
OCDATA=/var/ocdata
# Apache vhosts
SSL_CONF="/etc/apache2/sites-available/owncloud_ssl_domain_self_signed.conf"
HTTP_CONF="/etc/apache2/sites-available/owncloud_http_domain_self_signed.conf"
# Network
IFACE=$(lshw -c network | grep "logical name" | awk '{print $3; exit}')
ADDRESS=$(hostname -I | cut -d ' ' -f 1)
# Repositories
GITHUB_REPO="https://raw.githubusercontent.com/techandme/owncloud-vm/master/beta"
STATIC="https://raw.githubusercontent.com/techandme/owncloud-vm/master/static"
DOWNLOADREPO="https://download.owncloud.org/community/testing/owncloud-$OCVERSION"
# Commands
CLEARBOOT=$(dpkg -l linux-* | awk '/^ii/{ print $2}' | grep -v -e `uname -r | cut -f1,2 -d"-"` | grep -e [0-9] | xargs sudo apt -y purge)
# Linux user, and ownCloud user
UNIXUSER=ocadmin
UNIXPASS=owncloud

# DEBUG mode
if [ $DEBUG -eq 1 ]
then
    set -e
    set -x
else
    sleep 1
fi

# Check if root
        if [ "$(whoami)" != "root" ]; then
        echo
        echo -e "\e[31mSorry, you are not root.\n\e[0mYou must type: \e[36msudo \e[0mbash $SCRIPTS/owncloud_install.sh"
        echo
        exit 1
fi

DISTRO=$(lsb_release -sd | cut -d ' ' -f 2)
version(){
    local h t v

    [[ $2 = "$1" || $2 = "$3" ]] && return 0

    v=$(printf '%s\n' "$@" | sort -V)
    h=$(head -n1 <<<"$v")
    t=$(tail -n1 <<<"$v")

    [[ $2 != "$h" && $2 != "$t" ]]
}

if ! version 14.04 "$DISTRO" 16.04.4; then
    echo "Ubuntu version seems to be $DISTRO"
    echo "It must be between 14.04 - 16.04.4"
    echo "Please install that version and try again."
    exit 1
fi

if curl -s "$DOWNLOADREPO.zip" > /dev/null; then
        echo "ownCloud download file OK"
else
        echo "ownCloud download file is not availible, exiting..."
        exit 1
fi

# Check if it's a clean server
echo "Checking if it's a clean server..."
if [ $(dpkg-query -W -f='${Status}' mysql-common 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "MySQL is installed, it must be a clean server."
        exit 1
fi

if [ $(dpkg-query -W -f='${Status}' apache2 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "Apache2 is installed, it must be a clean server."
        exit 1
fi

if [ $(dpkg-query -W -f='${Status}' php 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "PHP is installed, it must be a clean server."
        exit 1
fi

if [ $(dpkg-query -W -f='${Status}' owncloud 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
	echo "ownCloud is installed, it must be a clean server."
	exit 1
fi

# Create $UNIXUSER if not existing
if id "$UNIXUSER" >/dev/null 2>&1
then
        echo "$UNIXUSER already exists!"
else
	adduser --disabled-password --gecos "" $UNIXUSER
        echo -e "$UNIXUSER:$UNIXPASS" | chpasswd
        usermod -aG sudo $UNIXUSER
fi

if [ -d /home/$UNIXUSER ];
then
	echo "$UNIXUSER OK!"
else
	echo "Something went wrong when creating the user... Script will exit."
	exit 1
fi

# Create $SCRIPTS dir
      	if [ -d $SCRIPTS ]; then
      		sleep 1
      		else
      	mkdir -p $SCRIPTS
fi

# Change DNS
if ! [ -x "$(command -v resolvconf)" ]; then
	apt install resolvconf -y -q
	dpkg-reconfigure resolvconf
else
	echo 'reolvconf is installed.' >&2
fi

echo "nameserver 8.26.56.26" > /etc/resolvconf/resolv.conf.d/base
echo "nameserver 8.20.247.20" >> /etc/resolvconf/resolv.conf.d/base

service networking restart

# Check network
if ! [ -x "$(command -v nslookup)" ]; then
	apt install dnsutils -y -q
else
	echo 'dnsutils is installed.' >&2
fi
if ! [ -x "$(command -v ifup)" ]; then
	apt install ifupdown -y -q
else
	echo 'ifupdown is installed.' >&2
fi
sudo ifdown $IFACE && sudo ifup $IFACE
nslookup google.com
if [[ $? > 0 ]]
then
	echo "Network NOT OK. You must have a working Network connection to run this script."
        exit 1
else
	echo "Network OK."
fi

# Update system
apt update -q2

# Set locales
apt install language-pack-en-base -y
sudo locale-gen "sv_SE.UTF-8" && sudo dpkg-reconfigure --frontend=noninteractive locales

# Install aptitude
apt install aptitude -y

# Write MySQL pass to file and keep it safe
echo "$MYSQL_PASS" > $PW_FILE
chmod 600 $PW_FILE
chown root:root $PW_FILE

# Install MYSQL 5.7
sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5072E1F5
apt install debconf-utils -y
export DEBIAN_FRONTEND=noninteractive
sudo apt purge mysql.* -y
sudo apt autoremove -y
sudo apt autoclean -y
sudo rm -rf /var/lib/mysql
sudo rm -rf /var/log/mysql

cat << SOURCES > "/etc/apt/sources.list.d/mysql.list"
deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.7
deb-src http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.7
SOURCES

echo "mysql-apt-config mysql-apt-config/repo-distro select ubuntu" | debconf-set-selections
echo "mysql-apt-config mysql-apt-config/repo-codename select trusty" | debconf-set-selections
echo "mysql-apt-config mysql-apt-config/select-server select mysql-5.7" | debconf-set-selections
echo "mysql-community-server mysql-community-server/root-pass password $MYSQL_PASS" | debconf-set-selections
echo "mysql-community-server mysql-community-server/re-root-pass password $MYSQL_PASS" | debconf-set-selections

sudo apt update -q
sudo apt install -q -y mysql-community-server

# mysql_secure_installation
apt -y install expect
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root:\"
send \"$MYSQL_PASS\r\"
expect \"Would you like to setup VALIDATE PASSWORD plugin?\"
send \"n\r\"
expect \"Change the password for root ?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "$SECURE_MYSQL"
apt -y purge expect

# Install Apache
apt install apache2 -y
a2enmod rewrite \
        headers \
        env \
        dir \
        mime \
        ssl \
        setenvif

# Set hostname and ServerName
sudo sh -c "echo 'ServerName owncloud' >> /etc/apache2/apache2.conf"
sudo hostnamectl set-hostname owncloud
service apache2 restart

# Install PHP 7.0
apt install python-software-properties -y && echo -ne '\n' | sudo add-apt-repository ppa:ondrej/php
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
        libsm6 \
	php-smbclient

# Enable SMB client
echo '# This enables php-smbclient' >> /etc/php/7.0/apache2/php.ini
echo 'extension="smbclient.so"' >> /etc/php/7.0/apache2/php.ini

# Download and install ownCloud
wget $DOWNLOADREPO.zip -P $HTML
apt install unzip -y
unzip -q $HTML/owncloud-$OCVERSION.zip -d $HTML
rm $HTML/owncloud-$OCVERSION.zip

mkdir -p $OCDATA

# Secure permissions
wget -q $STATIC/setup_secure_permissions_owncloud.sh -P $SCRIPTS
bash $SCRIPTS/setup_secure_permissions_owncloud.sh

# Install ownCloud
cd $OCPATH
sudo -u www-data php occ maintenance:install --data-dir "$OCDATA" --database "mysql" --database-name "owncloud_db" --database-user "root" --database-pass "$MYSQL_PASS" --admin-user "$UNIXUSER" --admin-pass "$UNIXPASS"
echo
echo ownCloud version:
sudo -u www-data php $OCPATH/occ status
echo
sleep 3

# Prepare cron.php to be run every 15 minutes
crontab -u www-data -l | { cat; echo "*/15  *  *  *  * php -f $OCPATH/cron.php > /dev/null 2>&1"; } | crontab -u www-data -

# Change values in php.ini (increase max file size)
# max_execution_time
sed -i "s|max_execution_time = 30|max_execution_time = 3500|g" /etc/php/7.0/apache2/php.ini
# max_input_time
sed -i "s|max_input_time = 60|max_input_time = 3600|g" /etc/php/7.0/apache2/php.ini
# memory_limit
sed -i "s|memory_limit = 128M|memory_limit = 512M|g" /etc/php/7.0/apache2/php.ini
# post_max
sed -i "s|post_max_size = 8M|post_max_size = 1100M|g" /etc/php/7.0/apache2/php.ini
# upload_max
sed -i "s|upload_max_filesize = 2M|upload_max_filesize = 1000M|g" /etc/php/7.0/apache2/php.ini

# Install Figlet
apt install figlet -y

# Generate $HTTP_CONF
if [ -f $HTTP_CONF ];
        then
        echo "Virtual Host exists"
else
        touch "$HTTP_CONF"
        cat << HTTP_CREATE > "$HTTP_CONF"
<VirtualHost *:80>

### YOUR SERVER ADDRESS ###
#    ServerAdmin admin@example.com
#    ServerName example.com
#    ServerAlias subdomain.example.com

### SETTINGS ###
    DocumentRoot $OCPATH

    <Directory $OCPATH>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    Satisfy Any
    </Directory>

    Alias /owncloud "$OCPATH/"

    <IfModule mod_dav.c>
    Dav off
    </IfModule>

    <Directory "$OCDATA">
    # just in case if .htaccess gets disabled
    Require all denied
    </Directory>

    SetEnv HOME $OCPATH
    SetEnv HTTP_HOME $OCPATH

</VirtualHost>
HTTP_CREATE
echo "$HTTP_CONF was successfully created"
sleep 3
fi

# Generate $SSL_CONF
if [ -f $SSL_CONF ];
        then
        echo "Virtual Host exists"
else
        touch "$SSL_CONF"
        cat << SSL_CREATE > "$SSL_CONF"
<VirtualHost *:443>
    Header add Strict-Transport-Security: "max-age=15768000;includeSubdomains"
    SSLEngine on

### YOUR SERVER ADDRESS ###
#    ServerAdmin admin@example.com
#    ServerName example.com
#    ServerAlias subdomain.example.com

### SETTINGS ###
    DocumentRoot $OCPATH

    <Directory $OCPATH>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    Satisfy Any
    </Directory>

    Alias /owncloud "$OCPATH/"

    <IfModule mod_dav.c>
    Dav off
    </IfModule>

    <Directory "$OCDATA">
    # just in case if .htaccess gets disabled
    Require all denied
    </Directory>

    SetEnv HOME $OCPATH
    SetEnv HTTP_HOME $OCPATH

### LOCATION OF CERT FILES ###
    SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
</VirtualHost>
SSL_CREATE
echo "$SSL_CONF was successfully created"
sleep 3
fi

# Enable new config
a2ensite owncloud_ssl_domain_self_signed.conf
a2ensite owncloud_http_domain_self_signed.conf
a2dissite default-ssl
service apache2 restart

## Set config values
# Experimental apps
sudo -u www-data php $OCPATH/occ config:system:set appstore.experimental.enabled --value="true"
# Default mail server (make this user configurable?)
sudo -u www-data php $OCPATH/occ config:system:set mail_smtpmode --value="smtp"
sudo -u www-data php $OCPATH/occ config:system:set mail_smtpauth --value="1"
sudo -u www-data php $OCPATH/occ config:system:set mail_smtpport --value="465"
sudo -u www-data php $OCPATH/occ config:system:set mail_smtphost --value="smtp.gmail.com"
sudo -u www-data php $OCPATH/occ config:system:set mail_smtpauthtype --value="LOGIN"
sudo -u www-data php $OCPATH/occ config:system:set mail_from_address --value="www.techandme.se"
sudo -u www-data php $OCPATH/occ config:system:set mail_domain --value="gmail.com"
sudo -u www-data php $OCPATH/occ config:system:set mail_smtpsecure --value="ssl"
sudo -u www-data php $OCPATH/occ config:system:set mail_smtpname --value="www.techandme.se@gmail.com"
sudo -u www-data php $OCPATH/occ config:system:set mail_smtppassword --value="vinr vhpa jvbh hovy"

# Install Libreoffice Writer to be able to read MS documents.
sudo apt install --no-install-recommends libreoffice-writer -y

# Install packages for Webmin
apt install -y zip perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python

# Install Webmin
sed -i '$a deb http://download.webmin.com/download/repository sarge contrib' /etc/apt/sources.list
wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -
apt update -q2
apt install webmin -y

# ownCloud apps
CONVER=$(wget -q https://raw.githubusercontent.com/owncloud/contacts/master/appinfo/info.xml && grep -Po "(?<=<version>)[^<]*(?=</version>)" info.xml && rm info.xml)
CONVER_FILE=contacts.tar.gz
CONVER_REPO=https://github.com/owncloud/contacts/releases/download
CALVER=$(wget -q https://raw.githubusercontent.com/nextcloud/calendar/master/appinfo/info.xml && grep -Po "(?<=<version>)[^<]*(?=</version>)" info.xml && rm info.xml)
CALVER_FILE=calendar.tar.gz
CALVER_REPO=https://github.com/nextcloud/calendar/releases/download

# Download and install Documents
if [ -d $OCPATH/apps/documents ]; then
sleep 1
else
wget -q https://github.com/owncloud/documents/archive/master.zip -P $OCPATH/apps
cd $OCPATH/apps
unzip -q master.zip
rm master.zip
mv documents-master/ documents/
fi

# Enable documents
if [ -d $OCPATH/apps/documents ]; then
sudo -u www-data php $OCPATH/occ app:enable documents
sudo -u www-data php $OCPATH/occ config:system:set preview_libreoffice_path --value="/usr/bin/libreoffice"
fi

# Download and install Contacts
if [ -d $OCPATH/apps/contacts ]; then
sleep 1
else
wget -q $CONVER_REPO/v$CONVER/$CONVER_FILE -P $OCPATH/apps
tar -zxf $OCPATH/apps/$CONVER_FILE -C $OCPATH/apps
cd $OCPATH/apps
rm $CONVER_FILE
fi

# Enable Contacts
if [ -d $OCPATH/apps/contacts ]; then
sudo -u www-data php $OCPATH/occ app:enable contacts
fi

# Download and install Calendar
if [ -d $OCPATH/apps/calendar ]; then
sleep 1
else
wget -q $CALVER_REPO/v$CALVER/$CALVER_FILE -P $OCPATH/apps
tar -zxf $OCPATH/apps/$CALVER_FILE -C $OCPATH/apps
cd $OCPATH/apps
rm $CALVER_FILE
fi

# Enable Calendar
if [ -d $OCPATH/apps/calendar ]; then
sudo -u www-data php $OCPATH/occ app:enable calendar
fi

# Set secure permissions final (./data/.htaccess has wrong permissions otherwise)
bash $SCRIPTS/setup_secure_permissions_owncloud.sh

# Change $UNIXUSER .bash_profile
        if [ -f $SCRIPTS/change-ocadmin-profile.sh ];
                then
                echo "change-ocadmin-profile.sh  exists"
                else
        wget -q $STATIC/change-ocadmin-profile.sh -P $SCRIPTS
fi
# Get startup-script for root
        if [ -f $SCRIPTS/owncloud-startup-script.sh ];
                then
                echo "owncloud-startup-script.sh exists"
                else
        wget -q $GITHUB_REPO/owncloud-startup-script.sh -P $SCRIPTS
fi

# Welcome message after login (change in /home/$UNIXUSER/.profile
        if [ -f $SCRIPTS/instruction.sh ];
                then
                echo "instruction.sh exists"
                else
        wget -q $STATIC/instruction.sh -P $SCRIPTS
fi
# Clears command history on every login
        if [ -f $SCRIPTS/history.sh ];
                then
                echo "history.sh exists"
                else
        wget -q $STATIC/history.sh -P $SCRIPTS
fi

# Get script for Redis
        if [ -f $SCRIPTS/install-redis-php-7.sh ];
                then
                echo "install-redis-php-7.sh exists"
                else
        wget -q $STATIC/install-redis-php-7.sh -P $SCRIPTS
fi

# Make $SCRIPTS excutable
chmod +x -R $SCRIPTS
chown root:root -R $SCRIPTS

# Allow $UNIXUSER to run theese scripts
chown $UNIXUSER:$UNIXUSER $SCRIPTS/instruction.sh
chown $UNIXUSER:$UNIXUSER $SCRIPTS/history.sh

# Install Redis
bash $SCRIPTS/install-redis-php-7.sh
rm $SCRIPTS/install-redis-php-7.sh

# Upgrade
aptitude full-upgrade -y

cat << TMPMSG > "$SCRIPTS/tempmsg.sh"
clear
echo "The default password is 'owncloud'."
echo
TMPMSG

# Prepare for startup-script after reboot
sed -i "s|owncloud_install.sh|owncloud-startup-script.sh|g" $SCRIPTS/change-root-profile.sh
sed -i "s|rm /root/.profile||g" $SCRIPTS/change-root-profile.sh
sed -i "s|bash /var/scripts/instruction.sh|bash $SCRIPTS/tempmsg.sh|g" $SCRIPTS/change-ocadmin-profile.sh

# Change root profile
bash $SCRIPTS/change-root-profile.sh
if [[ $? > 0 ]]
then
	echo "change-root-profile.sh were not executed correctly."
	sleep 10
else
	echo "change-root-profile.sh script executed OK."
	rm $SCRIPTS/change-root-profile.sh
	sleep 2
fi

# Change $UNIXUSER profile
bash $SCRIPTS/change-ocadmin-profile.sh
if [[ $? > 0 ]]
then
	echo "change-ocadmin-profile.sh were not executed correctly."
	sleep 10
else
	echo "change-ocadmin-profile.sh executed OK."
	rm $SCRIPTS/change-ocadmin-profile.sh
	sleep 2
fi

# Clean up rc.local
echo "Writes to rc.local..."
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

# Cleanup
echo "$CLEARBOOT"
apt autoremove -y
apt autoclean
if [ -f /home/$UNIXUSER/*.sh ];
then
	rm /home/$UNIXUSER/*.sh
fi

if [ -f /root/*.sh ];
then
	rm /root/*.sh
fi

# Reboot
reboot
