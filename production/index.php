<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head><title>ownCloud - Tech and Me</title>
<style>
body {
	background-color: #1d2d44;
	font-weight: 300;
	font-size: 1em;
	line-height: 1.6em;
	font-family: 'Open Sans', Frutiger, Calibri, 'Myriad Pro', Myriad, sans-serif;
	color: white;
	height: auto;
	margin-left: auto;
	margin-right: auto;
	align: center;
	text-align: center;
	background: #1d2d44; /* Old browsers */
	background-image: url('https://raw.githubusercontent.com/owncloud/core/master/core/img/background.jpg');
	background-size: cover;
}
div.logotext   {
	width: 50%;
    	margin: 0 auto;
}
div.logo   {
        background-image: url('/owncloud/core/img/logo-icon.svg');
        background-repeat: no-repeat; top center;
        width: 50%;
	height: 25%;
        margin: 0 auto;
	background-size: 40%;
	margin-left: 40%;
        margin-right: 20%;
}
pre  {
	padding:10pt;
	width: 50%
        text-align: center;
        margin-left: 20%;
	margin-right: 20%;
}
div.information {
        align: center;
	width: 50%;
        margin: 10px auto;
	display: block;
        padding: 10px;
        background-color: rgba(0,0,0,.3);
        color: #fff;
        text-align: left;
        border-radius: 3px;
        cursor: default;
}
/* unvisited link */
a:link {
    color: #FFFFFF;
}
/* visited link */
a:visited {
    color: #FFFFFF;
}
/* mouse over link */
a:hover {
    color: #E0E0E0;
}
/* selected link */
a:active {
    color: #E0E0E0;
}
</style>

<br>
<div class="logo">
</div>
<div class="logotext">
<h2>ownCloud VM - <a href="https://www.techandme.se/pre-configured-owncloud-installaton/" target="_blank">Tech and Me</a></h2>
</div>
<br>
<div class="information">
<p>Thank you for downloading the pre-configured ownCloud VM! If you see this page, you have successfully mounted the  ownCloud VM on the computer that will act as host for ownCloud.</p>
<p>We have set everything up for you and the only thing you have to do now is to login. You can find login details in the middle of this page.</p>
<p>Don't hesitate to ask if you have any questions. My email is: <a href="mailto:daniel@techandme.se?Subject=Before%20login%20-%20ownCloud%20VM" target="_top">daniel@techandme.se</a> You can also check the <a href="https://www.techandme.se/complete-install-instructions-owncloud/" target="_blank">complete install instructions</a>.</p>
<p>Please <a href="https://www.techandme.se/thank_you">donate</a> if you like it. All the donations will go to server costs and developing, making this VM even better.</p>

</div>

<h2><a href="https://www.techandme.se/user-and-password/" target="_blank">Login</a> to ownCloud</h2>

<div class="information">
<p>Default User:</p>
<h3>ocadmin</h3>
<p>Default Password:</p>
<h3>owncloud</h3>
<p>Note: The setup script will ask you to change the default password to your own. It's also recomended to change the default user. Do this by adding another admin user, log out from ocadmin, and login with your new user, then delete ocadmin.</p>
<br>
<center>
<h3> How to mount the VM and and login:</h3>
</center>
<p>Before you can use ownCloud you have to run the setup script to complete the installation. This is easily done by just typing 'owncloud' when you log in to the terminal for the first time.</p>
<p>The full path to the setup script is: /var/scripts/owncloud-startup-script.sh. When the script is finnished it will be deleted, as it's only used the first time you boot the machine.</p>
<center> 
<iframe width="560" height="315" src="https://www.youtube.com/embed/jhbkTQ9yA-4" frameborder="0" allowfullscreen></iframe>
</center>
</div>

<h2>Access ownCloud</h2>

<div class="information">
<p>Use one of the following addresses, HTTPS is preffered:
<h3>
<ul>
 <li><a href="http://<?=$_SERVER['SERVER_NAME'];?>/owncloud"        >http://<?=$_SERVER['SERVER_NAME'];?></a> (HTTP)
 <li><a href="https://<?=$_SERVER['SERVER_NAME'];?>/owncloud"             >https://<?=$_SERVER['SERVER_NAME'];?></a> (HTTPS)
 <p>
 </ul>
</h3>
<p>Note: Please accept the warning in the browser if you connect via HTTPS. It is recomended
<br> to <a href="https://www.techandme.se/publish-your-server-online" target="_blank">buy your own certificate and replace the self-signed certificate to your own.</a>
<br>
<p>Note: Before you can login you have to run the setup script, as descirbed in the video above.
</div>

<h2>Access Webmin</h2>

<div class="information">
<p>Use one of the following addresses, HTTPS is preffered:
<h3>
<ul>
 <li><a href="http://<?=$_SERVER['SERVER_NAME'];?>:10000"        >http://<?=$_SERVER['SERVER_NAME'];?></a> (HTTP)
 <li><a href="https://<?=$_SERVER['SERVER_NAME'];?>:10000"             >https://<?=$_SERVER['SERVER_NAME'];?></a> (HTTPS)
 <p>
 </ul>
</h3>
<p>Note: Please accept the warning in the browser if you connect via HTTPS.</p>
<h3>
<a href="https://www.techandme.se/user-and-password/" target="_blank">Login details</a>
</h3>
<p> Note: Webmin is installed when you run the setup script. To access Webmin externally you have to open port 10000 in your router.</p>
</div>

<h2>Access phpMyadmin</h2>

<div class="information">
<p>Use one of the following addresses, HTTPS is preffered:
<h3>
<ul>
 <li><a href="http://<?=$_SERVER['SERVER_NAME'];?>/phpmyadmin"        >http://<?=$_SERVER['SERVER_NAME'];?></a> (HTTP)
 <li><a href="https://<?=$_SERVER['SERVER_NAME'];?>/phpmyadmin"             >https://<?=$_SERVER['SERVER_NAME'];?></a> (HTTPS)
 <p>
 </ul>
</h3>
<p>Note: Please accept the warning in the browser if you connect via HTTPS.</p>
<h3>
<a href="https://www.techandme.se/user-and-password/" target="_blank">Login details</a>
</h3>
<p>Note: Your external IP is set as approved in /etc/apache2/conf-available/phpmyadmin.conf, all other access is forbidden.<p/>
</div>
