#!/bin/bash
# Maybe want to use later:
# sed -i "s| SSLCertificateChainFile /etc/letsencrypt/live/ENTER-YOUR-DOMAIN-HERE.COM/chain.pem| SSLCertificateChainFile /etc/letsencrypt/live/$domain/chain.pem|g" /etc/apache2/sites-available/lets_encrypt.conf
# sed -i "s| SSLCertificateFile /etc/letsencrypt/live/ENTER-YOUR-DOMAIN-HERE.COM/cert.pem| SSLCertificateFile /etc/letsencrypt/live/$domain/cert.pem|g" /etc/apache2/sites-available/lets_encrypt.conf
# sed -i "s| SSLCertificateKeyFile /etc/letsencrypt/live/ENTER-YOUR-DOMAIN-HERE.COM/privkey.pem| SSLCertificateKeyFile /etc/letsencrypt/live/$domain/privkey.pem|g" /etc/apache2/sites-available/lets_encrypt.conf

# sed -i "s| ServerAdmin admin@ENTER-YOUR-DOMAIN-HERE.COM| ServerAdmin admin@$domain|g" /etc/apache2/sites-available/lets_encrypt.conf
# sed -i "s| ServerName ENTER-YOUR-DOMAIN-HERE.COM| ServerName $domain|g" /etc/apache2/sites-available/lets_encrypt.conf

# Acitvate the new config
        echo -e "\e[0m"
        echo "Apache will now reboot"
        echo -e "\e[32m"
        read -p "Press any key to continue... " -n1 -s
        echo -e "\e[0m"
        a2ensite owncloud_ssl_domain.conf
        a2dissite owncloud_ssl_domain_self_signed.conf
        service apache2 restart
if [[ "$?" == "0" ]];
then
        echo -e "\e[91m"
        echo "New settings works! SSL is now activated and OK!"
        echo -e "\e[0m"
	echo
	echo "This script will expire in 90 days, so you have to renew it."
	echo "There are several ways of doing so, here are some tips and tricks: https://goo.gl/c1JHR0"
	echo "Feel free to contribute to this project: https://goo.gl/vEsWjb"
	echo -e "\e[32m"
    	read -p "Press any key to continue... " -n1 -s
    	echo -e "\e[0m"
else
# If it fails, revert changes back to normal
        a2dissite owncloud_ssl_domain.conf
        a2ensite owncloud_ssl_domain_self_signed.conf
        service apache2 restart
        echo -e "\e[96m"
        echo "Couldn't load new config, reverted to old settings. SSL is OK!"
        echo -e "\e[0m"
        echo -e "\e[32m"
        read -p "Press any key to continue... " -n1 -s
        echo -e "\e[0m"
	exit 1
fi

exit 0

