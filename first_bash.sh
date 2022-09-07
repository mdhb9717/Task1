#!/usr/bin/bash

# updating system
cd ~
sudo apt update

# installing nginx
sudo apt install nginx

# adjusting firewall to nginx
sudo ufw allow 'Nginx HTTP'

# checking web server status
systemctl status nginx --no-pager

# installing php required modules
sudo apt install software-properties-common ca-certificates lsb-release apt-transport-https
sudo LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt install --no-install-recommends php8.1
sudo apt-get install -y php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath

# installing composer
cd ~
sudo apt install php-cli unzip
sudo apt install curl
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
HASH=`curl -sS https://composer.github.io/installer.sig`
php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
composer

# getting database name
echo 'Enter your database name: ' 
read database_name
echo 'Enter your username: '
read username
echo 'Enter your database password: '
read passwddb

# create database
sudo apt install mysql-server
sudo systemctl start mysql.service --no-pager
sudo mysql -e "CREATE DATABASE $database_name;"
sudo mysql -e "CREATE USER '$username'@'localhost' IDENTIFIED WITH mysql_native_password BY '$passwddb';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $database_name.* TO $username@localhost;"

# Get Laravael Project from git hub 
git clone git@github.com:mdhb9717/laravel.git

# go to project directory and make .env
cd laravel
sudo touch .env
sudo cp .env.example .env
composer update

#configuring database
env_file=".env"
sudo sed -i "s/DB_HOST=127.0.0.1/DB_HOST=localhost/g" $env_file
sudo sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$database_name/g" $env_file
sudo sed -i "s/DB_USERNAME=root/DB_USERNAME=$username/g" $env_file
sudo sed -i "s/DB_PASSWORD=/DB_PASSWORD=$passwddb/g" $env_file

#setting up nginx
cd ~
sudo mv ~/laravel /var/www/laravel
php artisan migrate

#giving access to storage and cache
sudo chown -R www-data.www-data /var/www/laravel/storage
sudo chown -R www-data.www-data /var/www/laravel/bootstrap/cache

#make new virtual host
sudo cp /var/www/laravel/laravel /etc/nginx/sites-available/laravel

#activate new virtual host
sudo ln -s /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/

#confirm that the configuration doesn’t contain any syntax errors
sudo nginx -t

#apply changes & reloding nginx
sudo systemctl reload nginx

#Generate your application encryption key
cd /var/www/laravel
sudo php artisan key:generate
