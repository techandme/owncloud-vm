#!/bin/bash

# Tech and Me ©2016, www.techandme.se

# Must be root
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script, in Ubuntu type: sudo -i"; exit 1; }

# Get packages to be able to install Redis
apt-get update && sudo apt-get install build-essential -q -y
apt-get install tcl8.5 -q -y
apt-get install php-pear php5-dev -q -y

# Get latest Redis
wget -q http://download.redis.io/releases/redis-stable.tar.gz && tar -xzf redis-stable.tar.gz
mv redis-stable redis

# Test Redis
cd redis && make && taskset -c 1 make test
if [[ $? > 0 ]]
then
    echo "Test failed."
    exit
else
    echo -e "\e[32m"
    echo "Redis test OK!"
    echo -e "\e[0m"
fi

# Install Redis
make install
cd utils && yes "" | sudo ./install_server.sh 
if [[ $? > 0 ]]
then
    echo "Installation failed."
    exit
else
		echo -e "\e[32m"
    echo "Redis installation OK!"
    echo -e "\e[0m"
fi

# PECL install Redis
pecl install -Z redis
touch /etc/php5/mods-available/redis.ini
echo 'extension=redis.so' > /etc/php5/mods-available/redis.ini
php5enmod redis && service apache2 restart

# Check version
echo "This is the version installed for both Redis and the PHPmodule:"
echo
redis-server -v
php --ri redis
sleep 3
clear

# Prepare for adding redis configuration
sed -i "s|);||g" /var/www/owncloud/config/config.php

# Add the needed config to ownClouds config.php
cat <<ADD_TO_CONFIG>> /var/www/owncloud/config/config.php
  'memcache.local' => '\\OC\\Memcache\\Redis',
  'filelocking.enabled' => 'true',
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' =>
  array (
  'host' => 'localhost',
  'port' => 6379,
  'timeout' => 0,
  'dbindex' => 0,
  ),
);
ADD_TO_CONFIG

# Remove installation package
rm -rf redis
rm -rf redis-stable.tar.gz
apt-get autoremove -y
apt-get autoclean

exit 0
