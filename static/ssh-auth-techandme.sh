#!/bin/bash

# This script will authorize Tech and Me to access your server via SSH.
# Please run this by typing this command: 'sudo bash ssh-auth-techandme.sh'

#################################################################
# Please select which user to grant access for Tech and Me by	#
# typing the username of the user.				#
# If the user doesn't exist, it will be created automatically.	#
USER=techandme							#
#################################################################

USERPASS=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
AUTHFILEROOT=/$USER/.ssh/authorized_keys
AUTHFILEUSER=/home/$USER/.ssh/authorized_keys
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
LANIP=$(hostname -I | cut -d ' ' -f 1)

# Must be root
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script, in Ubuntu type: sudo bash ssh-auth-techandme.sh"; exit 1; }

# Create $USER if not existing
getent passwd $USER  > /dev/null
if [ $? -eq 0 ]
then
        echo "$USER already exists!"
else
	adduser --disabled-password --gecos "" $USER
        echo -e "$USER:$USERPASS" | chpasswd
        usermod -aG sudo $USER
fi

if [ -d /home/$USER ];
then
	echo "$USER OK!"
else
	echo "Something went wrong when creating the user... Script will exit."
	exit 1
fi

if [ "$USER" = "root" ];
then
	mkdir -p /$USER/.ssh/
	touch $AUTHFILEROOT
	cat << SSH_AUTH >> "$AUTHFILEROOT"

# Tech and Me
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCiZsWBEV+XD5mWjZoljRFGgU7sViF9OC/RMKS2E4ew1EdzW98ffA8g+efD7hLHsQxWmUyhk248bSkTvXYICyNI77DFVS7Yc+9dcDD/hAn/FQxxyt8kZTfE7/ktZkP9BW2/HnQdNHiRVu5PvdaAUlwLbLlri+WKh/rUhAdSmJMXVE9ev1M2lH4VnG0Kxtau+cxTrxI+wuW+sGyYEnr1dv4eOV7EIvVxJx9nPpaHIHUwAAl+gqMFRuXQJ9tWPXAJ1O0oeFmfR0DzGLUo6RaLNgY9qEMf159o23sBZEuvRdz+TAf65GgSBylnpaut8c0qUxDJHPF2NDhZhVcM4vQ6Be/byIUYhFjosD2Hrixqi0SxjZdZyMczchalXh0LTuItQni4/M7sn707eBV/FiED/1RTMszqwppWalRdNFi5LklsEG0UVZAhIyccL0cQFcH+vkDNZB/elt4Ir55jjOQxCNuOhiRlohTNKg3vomb61gsmpI4Aen4a0yHVvJKuibBpTOPS0RdWGTIBIuFvL8fR7o24zGDh7g0mgoBkFj4mfRalRrcGG0aljCm86gFIOepyrXW+xO93z+9XI1oLv7YWb1TvdehczNrgrV/kjAGNH39Jssxod6E+9iQ3yJJre8TQQCORSmD8yH2GC6Lof1qijbrBzb9PXvOXGBksxULYukgoDw== techandme_ssh_auth
SSH_AUTH
else
        mkdir -p /home/$USER/.ssh/
        touch $AUTHFILEUSER
	cat << SSH_AUTH >> "$AUTHFILEUSER"

# Tech and Me
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCiZsWBEV+XD5mWjZoljRFGgU7sViF9OC/RMKS2E4ew1EdzW98ffA8g+efD7hLHsQxWmUyhk248bSkTvXYICyNI77DFVS7Yc+9dcDD/hAn/FQxxyt8kZTfE7/ktZkP9BW2/HnQdNHiRVu5PvdaAUlwLbLlri+WKh/rUhAdSmJMXVE9ev1M2lH4VnG0Kxtau+cxTrxI+wuW+sGyYEnr1dv4eOV7EIvVxJx9nPpaHIHUwAAl+gqMFRuXQJ9tWPXAJ1O0oeFmfR0DzGLUo6RaLNgY9qEMf159o23sBZEuvRdz+TAf65GgSBylnpaut8c0qUxDJHPF2NDhZhVcM4vQ6Be/byIUYhFjosD2Hrixqi0SxjZdZyMczchalXh0LTuItQni4/M7sn707eBV/FiED/1RTMszqwppWalRdNFi5LklsEG0UVZAhIyccL0cQFcH+vkDNZB/elt4Ir55jjOQxCNuOhiRlohTNKg3vomb61gsmpI4Aen4a0yHVvJKuibBpTOPS0RdWGTIBIuFvL8fR7o24zGDh7g0mgoBkFj4mfRalRrcGG0aljCm86gFIOepyrXW+xO93z+9XI1oLv7YWb1TvdehczNrgrV/kjAGNH39Jssxod6E+9iQ3yJJre8TQQCORSmD8yH2GC6Lof1qijbrBzb9PXvOXGBksxULYukgoDw== techandme_ssh_auth
SSH_AUTH
fi
if [[ $? > 0 ]]
then
        echo "------------------------------------------------------------------------"
        echo -e "\e[41m"
        echo "SSH installation failed!"
        echo -e "\e[0m"
        echo "------------------------------------------------------------------------"
	exit 1
else
        # echo -e "\e[92m"
        echo "------------------------------------------------------------------------"
        echo -e "\e[92mSSH installation success!"
        echo
        echo -e "\e[92m$USER@$WANIP"
        echo -e "Password: $USERPASS\e[0m"
        echo "Please email daniel@techandme.se and let us know that this is set up,"
        echo "please also provide the above information in the email to us."
        echo "Thank you."
        echo "------------------------------------------------------------------------"
        service ssh restart > /dev/null
fi

# Test if port 22 is open
echo "Testing if port 22 is open..."
nc -z -v -w5 $WANIP 22 > /dev/null
if [[ $? > 0 ]]
then
        echo -e "\e[41mPort 22 is not open, you have to open this before we can connect.\e[0m"
        echo
	echo "Please open port 22 in your firewall or router against the servers IP:"
        echo $LANIP
        echo "A guide on how to open ports can be found here: https://goo.gl/Uyuf65"
        echo
        exit 1
else
        echo -e "\e[92m"
        echo "Port 22 is open, Tech and Me can now connect."
        echo -e "\e[0m"
	exit 0
fi
