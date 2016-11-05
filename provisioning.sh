#!/usr/bin/env bash

debconf-set-selections <<< 'mysql-server mysql-server/root_password password mypassword'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password mypassword'

echo "Install software"
apt-get update
# apt-get upgrade
apt-get install -y nginx nginx-extras 
apt-get install -y php5-cli php5-common php5-mysql php5-gd php5-fpm php5-cgi php5-fpm php-pear php5-mcrypt # php5-intl
apt-get install -y mysql-server mysql-client
apt-get install -y git

echo "copy nginx configuration"
cp /vagrant/configs/nginx_payever.conf /etc/nginx/sites-available/payever.conf

echo "create link in sites-enabled if not exist"
if [ ! -f /etc/nginx/sites-enabled/payever.conf ]; then
	ln -s /etc/nginx/sites-available/payever.conf /etc/nginx/sites-enabled/payever.conf
fi

if [ -f /etc/nginx/sites-enabled/default ]; then
	echo "unlink default host"
	unlink /etc/nginx/sites-enabled/default
fi

if [ -f /etc/php5/fpm/pool.d/www.conf ]; then
	echo "remove default php-fpm pool"
	rm /etc/php5/fpm/pool.d/www.conf
fi

echo "copy php-fpm configuration"
cp /vagrant/configs/php_fpm_payever.conf /etc/php5/fpm/pool.d/payever.conf

echo "set timezone"
sed -i "s/;date.timezone =.*/date.timezone = Europe\/Moscow/" /etc/php5/fpm/php.ini
sed -i "s/;date.timezone =.*/date.timezone = Europe\/Moscow/" /etc/php5/cli/php.ini

echo "reload services"
service php5-fpm reload
service nginx reload


echo "create folders for Symfony"
if [ ! -d /var/www/payever/app/cache/ ]; then
	mkdir /var/www/payever/app/cache/
fi
if [ ! -d /var/www/payever/app/logs/ ]; then
	mkdir /var/www/payever/app/logs/
fi
chown vagrant:vagrant /var/www/payever/app/cache/
chown vagrant:vagrant /var/www/payever/app/logs/


cd /var/www/payever

if [ ! -f /var/www/payever/composer.phar ]; then
	echo "Install Composer"
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	php -r "if (hash_file('SHA384', 'composer-setup.php') === 'aa96f26c2b67226a324c27919f1eb05f21c248b987e6195cad9690d5c1ff713d53020a02ac8c217dbf90a7eacc9d141d') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
	php composer-setup.php
	php -r "unlink('composer-setup.php');"
fi

echo "Install Symfony modules"
php composer.phar install