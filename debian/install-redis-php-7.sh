#!bin/bash

# Tech and Me - www.techandme.se - ©2016

SCRIPTS=/var/scripts

# Must be root
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script, in Ubuntu type: sudo -i"; exit 1; }

# Check if dir exists
if [ -d $SCRIPTS ];
then sleep 1
else mkdir -p $SCRIPTS
fi

# Get packages to be able to install Redis
aptitude update && sudo aptitude install build-essential -q -y
aptitude install tcl8.5 -q -y
aptitude install php-pear php7.0-dev -q -y

# Install Git and clone repo
aptitude install git -y -q
git clone -b php7 https://github.com/phpredis/phpredis.git

# Build Redis PHP module
aptitude install php7.0-dev -y
sudo mv phpredis/ /etc/ && cd /etc/phpredis
phpize
./configure
make && make install
if [[ $? > 0 ]]
then
    echo "PHP module installation failed"
    sleep 5
    exit 1
else
		echo -e "\e[32m"
    echo "PHP module installation OK!"
    echo -e "\e[0m"
fi
echo 'extension=redis.so' >> /etc/php/7.0/apache2/php.ini
touch /etc/php/mods-available/redis.ini
echo 'extension=redis.so' > /etc/php/mods-available/redis.ini
phpenmod redis
service apache2 restart
cd ..
rm -rf phpredis

# Get latest Redis
wget -q http://download.redis.io/releases/redis-stable.tar.gz -P $SCRIPTS && tar -xzf $SCRIPTS/redis-stable.tar.gz -C $SCRIPTS
mv $SCRIPTS/redis-stable $SCRIPTS/redis

# Test Redis
cd $SCRIPTS/redis && make && taskset -c 1 make test
if [[ $? > 0 ]]
then
    echo "Test failed."
    sleep 5
    exit 1
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
    sleep 5
    exit 1
else
                echo -e "\e[32m"
    echo "Redis installation OK!"
    echo -e "\e[0m"
fi

# Remove installation package
rm -rf $SCRIPTS/redis
rm $SCRIPTS/redis-stable.tar.gz

# Prepare for adding redis configuration
sed -i "s|);||g" /var/www/html/owncloud/config/config.php

# Add the needed config to ownClouds config.php
cat <<ADD_TO_CONFIG>> /var/www/html/owncloud/config/config.php
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

# Cleanup
aptitude purge git -y

exit 0
