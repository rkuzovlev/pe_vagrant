#!/usr/bin/env bash

sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password mypassword'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password mypassword'

echo "Install software"
sudo apt-get update
# apt-get upgrade
sudo apt-get install -y nginx nginx-extras 
sudo apt-get install -y php5-cli php5-common php5-mysql php5-gd php5-fpm php5-cgi php5-fpm php-pear php5-mcrypt # php5-intl
sudo apt-get install -y mysql-server mysql-client
sudo apt-get install -y git

echo "Install NodeJS"
curl -sL https://deb.nodesource.com/setup_4.x | sudo bash -
sudo apt-get -y install build-essential nodejs

if [ ! -f /swapfile ]; then
	echo "Create swap file"
	sudo fallocate -l 1G /swapfile
	sudo chmod 600 /swapfile
	sudo mkswap /swapfile
	sudo swapon /swapfile
fi

echo "Create database and user in mysql"
echo "CREATE DATABASE IF NOT EXISTS payever CHARACTER SET utf8 COLLATE utf8_general_ci;" | mysql -uroot -hlocalhost -pmypassword
echo "GRANT ALL ON payever.* TO payever@localhost IDENTIFIED BY 'mypassword';" | mysql -uroot -hlocalhost -pmypassword

echo "copy nginx configuration"
sudo cp /vagrant/configs/nginx_payever.conf /etc/nginx/sites-available/payever.conf

if [ ! -f /etc/nginx/sites-enabled/payever.conf ]; then
	echo "create link in sites-enabled if not exist"
	sudo ln -s /etc/nginx/sites-available/payever.conf /etc/nginx/sites-enabled/payever.conf
fi

if [ -f /etc/nginx/sites-enabled/default ]; then
	echo "unlink default host"
	sudo unlink /etc/nginx/sites-enabled/default
fi

if [ -f /etc/php5/fpm/pool.d/www.conf ]; then
	echo "remove default php-fpm pool"
	sudo rm /etc/php5/fpm/pool.d/www.conf
fi

echo "copy php-fpm configuration"
sudo cp /vagrant/configs/php_fpm_payever.conf /etc/php5/fpm/pool.d/payever.conf

echo "set timezone"
sudo sed -i "s/;date.timezone =.*/date.timezone = Europe\/Moscow/" /etc/php5/fpm/php.ini
sudo sed -i "s/;date.timezone =.*/date.timezone = Europe\/Moscow/" /etc/php5/cli/php.ini

echo "reload services"
sudo service php5-fpm reload
sudo service nginx reload


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

echo "copy symfony parameters"
cp /vagrant/configs/symfony_parameters.yml /var/www/payever/app/config/parameters.yml

echo "Install node modules"
sudo npm install -g gulp-cli