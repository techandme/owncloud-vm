#!/bin/bash

# Tech and Me, ©2017 - www.techandme.se

# Debian 8.3 Jessie

export CONVER=v1.2.0.0
export CONVER_FILE=contacts.tar.gz
export CONVER_REPO=https://github.com/owncloud/contacts/releases/download
export CALVER=v1.1
export CALVER_FILE=calendar.tar.gz
export CALVER_REPO=https://github.com/owncloud/calendar/releases/download
export OCDATA=/var/ocdata
export MYSQL_VERSION=5.7
export SHUF=$(shuf -i 13-15 -n 1)
export MYSQL_PASS=$(cat /dev/urandom | tr -dc "a-zA-Z0-9@#*=" | fold -w $SHUF | head -n 1)
export ROOT_PASS=$(cat /dev/urandom | tr -dc "a-zA-Z0-9@#*=" | fold -w $SHUF | head -n 1)
export PW_FILE=/var/M-R_passwords.txt
export SCRIPTS=/var/scripts
export HTML=/var/www
export OCPATH=$HTML/owncloud
export SSL_CONF="/etc/apache2/sites-available/owncloud_ssl_domain_self_signed.conf"
export IP="/sbin/ip"
export IFACE=$($IP -o link show | awk '{print $2,$9}' | grep "UP" | cut -d ":" -f 1)
export ADDRESS=$(hostname -I | cut -d ' ' -f 1)
export OCREPO="https://download.owncloud.org/download/repositories/stable/Debian_8.0"
export OCREPOKEY="$OCREPO/Release.key"


# Check if root
        if [ "$(whoami)" != "root" ]; then
        echo
        echo -e "\e[31mSorry, you are not root.\n\e[0mYou must type: \e[36msu root -c 'bash $SCRIPTS/owncloud_install.sh'"
        echo
        exit 1
fi

# Check if repo is availible
if curl -s "$OCREPO" > /dev/null; then
        echo "ownCloud repo OK"
else
        echo "ownCloud repo is not availible, exiting..."
        exit 1
fi

if curl -s "$OCREPOKEY" > /dev/null; then
        echo "ownCloud repo key OK"
else
        echo "ownCloud repo key is not availible, exiting..."
        exit 1
fi

# Check if it's a clean server
echo "Checking if it's a clean server..."
if dpkg --list mysql-common | egrep -q ^ii; then
        echo "MySQL is installed, it must be a clean server."
        exit 1
fi

if dpkg --list apache2 | egrep -q ^ii; then
        echo "Apache2 is installed, it must be a clean server."
        exit 1
fi

if dpkg --list php | egrep -q ^ii; then
        echo "PHP is installed, it must be a clean server."
        exit 1
fi

if dpkg --list owncloud | egrep -q ^ii; then
        echo "ownCloud is installed, it must be a clean server."
        exit 1
fi

# Change DNS
echo "nameserver 8.26.56.26" > /etc/resolv.conf
echo "nameserver 8.20.247.20" >> /etc/resolv.conf

# Check network
ifdown $IFACE && ifup $IFACE
nslookup google.com
if [[ $? > 0 ]]
then
    echo "Network NOT OK. You must have a working Network connection to run this script."
    exit
else
    echo "Network OK."
fi

# Update system
aptitude update

# Install Sudo
aptitude install sudo-y
adduser ocadmin sudo

# Install Rsync
aptitude install rsync-y

# Install figlet for techandme.sh
aptitude install figlet-y

# Set locales & timezone to Swedish
echo "Europe/Stockholm" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# sv_SE.UTF-8 UTF-8/sv_SE.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales

# Set Random passwords
echo
echo "The MySQL password will now be set..."
echo
sleep 2
echo -e "Your MySQL root password is: \e[32m$MYSQL_PASS\e[0m"
echo "Please save this somewhere safe. You can not login to MySQL without it." 
echo "The password is also saved in this file: $PW_FILE."
echo "MySQL password: $MYSQL_PASS" > $PW_FILE
echo -e "\e[32m"
read -p "Press any key to continue..." -n1 -s
echo -e "\e[0m"
echo
echo "The ROOT password will now change..."
echo
sleep 2
echo -e "root:$ROOT_PASS" | chpasswd
echo -e "Your new ROOT password is: \e[32m$ROOT_PASS\e[0m"
echo "Please save this somewhere safe. You can not login as root without it."
echo "The password is also saved in this file: $PW_FILE."
echo "ROOT password: $ROOT_PASS" >> $PW_FILE
chmod 600 $PW_FILE
echo -e "\e[32m"
read -p "Press any key to continue..." -n1 -s
echo -e "\e[0m"

# Install MYSQL 5.7
aptitude install debconf-utils-y
if [ -d /var/lib/mysql ];
then
rm -R /var/lib/mysql
fi
echo "deb http://repo.mysql.com/apt/debian/ jessie mysql-$MYSQL_VERSION" > /etc/apt/sources.list.d/mysql.list
echo "deb-src http://repo.mysql.com/apt/debian/ jessie mysql-$MYSQL_VERSION" >> /etc/apt/sources.list.d/mysql.list
echo mysql-community-server mysql-community-server/root-pass password $MYSQL_PASS | debconf-set-selections
echo mysql-community-server mysql-community-server/re-root-pass password $MYSQL_PASS | debconf-set-selections
apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5
aptitude update
aptitude install mysql-community-server-y

# mysql_secure_installation
aptitude-y install expect
export SECURE_MYSQL=$(expect -c "
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
unset SECURE_MYSQL
aptitude-y purge expect

# Install Apache
aptitude install apache2-y
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

# Install PHP 7
echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
wget https://www.dotdeb.org/dotdeb.gpg
apt-key add dotdeb.gpg
rm dotdeb.gpg
aptitude update
aptitude install-y \
        software-properties-common \
	php7.0 \
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
        php7.0-xmlrpc \
	libsm6 \
        libsmbclient

# Download and install ownCloud
wget -nv $OCREPOKEY -O Release.key
apt-key add - < Release.key && rm Release.key
sh -c "echo 'deb $OCREPO/ /' >> /etc/apt/sources.list.d/owncloud.list"
apt update -q2 && apt install owncloud-files-y

# Create data folder, occ complains otherwise
mkdir -p $OCDATA

# Secure permissions
wget https://raw.githubusercontent.com/techandme/owncloud-vm/master/static/setup_secure_permissions_owncloud.sh -P $SCRIPTS
chmod +x $SCRIPTS/setup_secure_permissions_owncloud.sh
bash $SCRIPTS/setup_secure_permissions_owncloud.sh

# Install ownCloud
cd $OCPATH
su -s /bin/sh -c 'php occ maintenance:install --data-dir "$OCDATA" --database "mysql" --database-name "owncloud_db" --database-user "root" --database-pass "$MYSQL_PASS" --admin-user "ocadmin" --admin-pass "owncloud"' www-data
echo
echo "ownCloud version:"
su -s /bin/sh -c 'php $OCPATH/occ status' www-data
echo
sleep 3

# Set trusted domain
wget https://raw.githubusercontent.com/techandme/owncloud-vm/master/static//update-config.php -P $SCRIPTS
chmod a+x $SCRIPTS/update-config.php
php $SCRIPTS/update-config.php $OCPATH/config/config.php 'trusted_domains[]' localhost ${ADDRESS[@]} $(hostname) $(hostname --fqdn) 2>&1 >/dev/null
php $SCRIPTS/update-config.php $OCPATH/config/config.php overwrite.cli.url https://$ADDRESS/owncloud 2>&1 >/dev/null

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
a2dissite default-ssl
service apache2 restart

## Set config values
# Experimental apps

su -s /bin/sh -c 'php $OCPATH/occ config:system:set appstore.experimental.enabled --value="true"' www-data
# Default mail server (make this user configurable?)
su -s /bin/sh -c 'php $OCPATH/occ config:system:set mail_smtpmode --value="smtp"' www-data
su -s /bin/sh -c 'php $OCPATH/occ config:system:set mail_smtpauth --value="1"' www-data
su -s /bin/sh -c 'php $OCPATH/occ config:system:set mail_smtpport --value="465"' www-data
su -s /bin/sh -c 'php $OCPATH/occ config:system:set mail_smtphost --value="smtp.gmail.com"' www-data
su -s /bin/sh -c 'php $OCPATH/occ config:system:set mail_smtpauthtype --value="LOGIN"' www-data
su -s /bin/sh -c 'php $OCPATH/occ config:system:set mail_from_address --value="www.en0ch.se"' www-data
su -s /bin/sh -c 'php $OCPATH/occ config:system:set mail_domain --value="gmail.com"' www-data
su -s /bin/sh -c 'php $OCPATH/occ config:system:set mail_smtpsecure --value="ssl"' www-data
su -s /bin/sh -c 'php $OCPATH/occ config:system:set mail_smtpname --value="www.en0ch.se@gmail.com"' www-data
su -s /bin/sh -c 'php $OCPATH/occ config:system:set mail_smtppassword --value="techandme_se"' www-data

# Install Libreoffice Writer to be able to read MS documents.
aptitude update
apt install --no-install-recommends libreoffice-writer-y

# Install unzip
aptitude install unzip-y

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
wget -q $CONVER_REPO/$CONVER/$CONVER_FILE -P $OCPATH/apps
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
wget -q $CALVER_REPO/$CALVER/$CALVER_FILE -P $OCPATH/apps
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

# Start startup-script
bash $SCRIPTS/owncloud-startup-script.sh

# Unset all $VARs
unset OCVERSION
unset MYSQL_VERSION
unset SHUF
unset MYSQL_PASS
unset PW_FILE
unset SCRIPTS
unset HTML
unset OCPATH
unset SSL_CONF
unset IFACE
unset ADDRESS
unset ROOT_PASS
unset IP
unset CONVER
unset CONVER_FILE
unset CONVER_REPO
unset CALVER
unset CALVER_FILE
unset CALVER_REPO
unset OCDATA

exit 0
