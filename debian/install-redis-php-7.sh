#!bin/bash

# Tech and Me - www.techandme.se - ©2016

SCRIPTS=/var/scripts
OCPATH=/var/www/owncloud
REDIS_CONF=/etc/redis/6379.conf
REDIS_INIT=/etc/init.d/redis_6379
REDIS_SOCK=/var/run/redis.sock

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
  'host' => '$REDIS_SOCK',
  'port' => 0,
  'timeout' => 0,
  'dbindex' => 0,
  ),
);
ADD_TO_CONFIG

# Redis performance tweaks
if	grep -Fxq "vm.overcommit_memory = 1" /etc/sysctl.conf
then
	echo "vm.overcommit_memory correct"
else
	echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
fi
sed -i "s|# unixsocket /tmp/redis.sock|unixsocket $REDIS_SOCK|g" $REDIS_CONF
sed -i "s|# unixsocketperm 700|unixsocketperm 777|g" $REDIS_CONF
sed -i "s|port 6379|port 0|g" $REDIS_CONF
sed -i "s|###############|SOCKET='$REDIS_SOCK'|g" $REDIS_INIT
sed -i "s|REDISPORT shutdown|SOCKET shutdown|g" $REDIS_INIT
sed -i "s|CLIEXEC -p|CLIEXEC -s|g" $REDIS_INIT
redis-cli SHUTDOWN

# Cleanup
aptitude purge -q -y \
	git \
	php7.0-dev \
	binutils \
	build-essential \
	cpp \
	cpp-4.8 \
	dpkg-dev \
	fakeroot \
	g++ \
	g++-4.8 \
	gcc \
	gcc-4.8 \
	libalgorithm-diff-perl \
	libalgorithm-diff-xs-perl \
	libalgorithm-merge-perl \
	libasan0 \
	libatomic1 \
	libc-dev-bin \
	libc6-dev \
	libcloog-isl4 \
	libdpkg-perl \
	libfakeroot \
	libfile-fcntllock-perl \
	libgcc-4.8-dev \
	libgmp10 libgomp1 \
	libisl10 \
	libitm1 \
	libmpc3 \
	libmpfr4 \
	libquadmath0 \
	libstdc++-4.8-dev \
	libtsan0 \
	linux-libc-dev \
	make \
	manpages-dev

aptitude update
aptitude autoremove -q -y
aptitude autoclean

exit 0
