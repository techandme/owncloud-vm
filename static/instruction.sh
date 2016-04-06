#!/bin/bash
#
clear
cat << INST1
+-----------------------------------------------------------------------+
| Thank you for downloading this ownCloud VM made by Tech and Me!       |
|                                                                       |
INST1
echo -e "|"  "\e[32mTo run the startup script type the sudoer password. This will either\e[0m  |"
echo -e "|"  "\e[32mbe the default ('owncloud') or the one chosen during installation.\e[0m    |"
cat << INST2
|                                                                       |
| If you have never done this before you can follow the complete        |
| installation instructions here: https://goo.gl/3FYtz6                 |
|                                                                       |
| You can schedule the ownCloud update process using a cron job.        |
| This is done using a script built into this VM that automatically     |
| updates ownCloud, sets secure permissions, and logs the successful    |
| update to /var/log/cronjobs_success.log                    		|
| Detailed instructions for setting this up can be found here:          |
| https://www.techandme.se/set-automatic-owncloud-updates/              |
|                                                                       |
|  ####################### Tech and Me - 2016 ########################  |
+-----------------------------------------------------------------------+
INST2

exit 0
