#!/bin/bash
### Set Language
TEXTDOMAIN=virtualhost

### Set default parameters
action=$1
domain=$2
name=$3
rootdir=$4
destiny=$5
ip=$6
owner=$(who am i | awk '{print $1}')
email='webmaster@localhost'
sitesEnable='/etc/apache2/sites-enabled/'
sitesAvailable='/etc/apache2/sites-available/'

### don't modify from here unless you know what you are doing ####

if [ "$(whoami)" != 'root' ]; then
  	echo $"You have no permission to run $0 as non-root user. Use sudo"
		exit 1;
fi

if [ "$action" != 'create' ] && [ "$action" != 'delete' ]
	then
		echo $"You need to prompt for action (create or delete) -- Lower-case only"
		exit 1;
fi

while [ "$domain" == ""  ]
do
	echo -e $"Please provide domain. e.g.dev,staging"
	read  domain
done

if [ "$destiny" == "" ]; then
	echo -e $"Please provide a destiny, '/srv/www/' or '~/projects'"
	read  destiny
fi

if [ "$name" == "" ]; then
	echo -e $"Please provide a simple name, for example domain"
	read  name
fi

if [ "$rootdir" == "" ]; then
	echo -e $"Please provide a rootdir, for example www or web or docroot"
	read  rootdir
fi

if [ "$ip" == "" ]; then
	echo -e $"Please provide an IP, 127.0.0.1"
	read  ip
fi

sitesAvailabledomain=$sitesAvailable$name.conf
completepath=$destiny/$name/$rootdir
echo $sitesAvailable \n
echo $sitesAvailabledomain \n
echo $completepath

#destiny='/var/www/'

if [ "$action" == 'create' ]
	then
		### check if domain already exists
		if [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain already exists.\nPlease Try Another one"
			exit;
		fi

		### check if directory exists or not
#		if ! [ -d $destiny$rootdir ]; then
#			### create the directory
#			mkdir $destiny$rootdir
#			### give permission to root dir
#			chmod 755 $destiny$rootdir
#			### write test file in the new domain dir
#			if ! echo "<?php echo phpinfo(); ?>" > $destiny$rootdir/phpinfo.php
#			then
#				echo $"ERROR: Not able to write in file $destiny/$rootdir/phpinfo.php. Please check permissions"
#				exit;
#			else
#				echo $"Added content to $destiny$rootdir/phpinfo.php"
#			fi
#		fi

		### create virtual host rules file
		if ! echo "
<VirtualHost *:80>
	ServerAdmin $email
	ServerName $domain
	ServerAlias $domain
	DocumentRoot $completepath
	<Directory />
		AllowOverride All
	</Directory>
	<Directory $completepath>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride all
		Require all granted
	</Directory>
	ErrorLog /var/log/apache2/$name-error.log
	LogLevel error
	CustomLog /var/log/apache2/$name-access.log combined
</VirtualHost>" > $sitesAvailabledomain
		then
			echo -e $"There is an ERROR creating $domain file"
			exit;
		else
			echo -e $"\nNew Virtual Host Created\n"
		fi

		### Add domain in /etc/hosts
		if ! echo "$ip	$domain" >> /etc/hosts
		then
			echo $"ERROR: Not able to write in /etc/hosts"
			exit;
		else
			echo -e $"Host added to /etc/hosts file \n"
		fi

#		if [ "$owner" == ""  ]; then
#			chown -R $(whoami):$(whoami) $destiny$rootdir
#		else
#			chown -R $owner:$owner $destiny$rootdir
#		fi

		### enable website
		a2ensite $domain

		### restart Apache
		/etc/init.d/apache2 reload

		### show the finished message
		echo -e $"Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $destiny$rootdir"
		exit;
	else

		###### Delete #######

		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit;
		else
			### Delete domain in /etc/hosts
			newhost=${domain//./\\.}
			sed -i "/$newhost/d" /etc/hosts

			### disable website
			a2dissite $domain

			### restart Apache
			/etc/init.d/apache2 reload

			### Delete virtual host rules files
			rm $sitesAvailabledomain
		fi

		### check if directory exists or not
		if [ -d $destiny$rootdir ]; then
			echo -e $"Delete host root directory ? (y/n)"
			read deldir

			if [ "$deldir" == 'y' -o "$deldir" == 'Y' ]; then
				### Delete the directory
				rm -rf $destiny$rootdir
				echo -e $"Directory deleted"
			else
				echo -e $"Host directory conserved"
			fi
		else
			echo -e $"Host directory not found. Ignored"
		fi

		### show the finished message
		echo -e $"Complete!\nYou just removed Virtual Host $domain"
		exit 0;
fi
