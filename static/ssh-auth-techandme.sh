#!/bin/bash

# This script will authorize Tech and Me to access your server via SSH.
# Please run this by typing this command: 'sudo bash ssh-auth-techandme.sh'

# Please select which user to grant access (root is preferred)

#############
            #
USER=root	  #
            #
#############

AUTHFILEROOT=/$USER/.ssh/authorized_keys
AUTHFILEUSER=/home/$USER/.ssh/authorized_keys

# Must be root
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script, in Ubuntu type: sudo bash ssh-auth-techandme.sh"; exit 1; }

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
	echo
	echo "SSH installation failed!"
	echo
    	exit 1
else
    	echo
    	echo "SSH installation success!"
    	echo
    	echo "Please email daniel@techandme.se and let us know that this is setup."
    	echo "Include your external IP address in the email, and also open port 22"
    	echo "in your firewall or router against the servers internal IP. Thank you!"
    	echo
	service ssh restart
fi

exit 0
