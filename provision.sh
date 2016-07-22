#!/bin/bash

#
# This configuration is actual for Ubuntu 14.04
#

export DEBIAN_FRONTEND=noninteractive

echo '
----------------------------------------
Prepare Environment
----------------------------------------
';

sudo usermod -a -G www-data vagrant

sudo apt-get update

sudo apt-get -y install git

sudo apt-get -y install mc

sudo apt-get -y install nginx

sudo add-apt-repository ppa:ondrej/php
sudo apt-get update

sudo apt-get -y install php7.0 php7.0-cli php7.0-fpm
sudo apt-get -y install php7.0-mysql php7.0-gd php7.0-json php7.0-xml php7.0-curl php7.0-mbstring
sudo apt-get -y install php7.0-readline php7.0-opcache php7.0-mcrypt

echo "mysql-server mysql-server/root_password password 1q2w3e4r" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password 1q2w3e4r" | sudo debconf-set-selections

apt-get -y install mysql-server

sed -i s/\;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/ /etc/php/7.0/fpm/php.ini
sed -i s/display_errors\ =\ Off/display_errors\ =\ On/ /etc/php/7.0/fpm/php.ini
sed -i s/max_execution_time\ =\ 30/max_execution_time\ =\ 300/ /etc/php/7.0/fpm/php.ini
sed -i s/listen\ =\ 127.0.0.1:9000/listen\ =\ \\/var\\/run\\/php\\/php7.0-fpm.sock/ /etc/php/7.0/fpm/pool.d/www.conf

sudo sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/my.cnf
mysql -uroot -p1q2w3e4r -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="1q2w3e4r"; FLUSH PRIVILEGES;'

sudo service nginx restart
sudo service php7.0-fpm restart
sudo service mysql restart

echo '
----------------------------------------
DONE!
----------------------------------------
';

echo '
----------------------------------------
Installing Yii2 Advanced Application Template
Configure needed packages...
----------------------------------------
';

rm -f /etc/nginx/sites-available/yiitest-front /etc/nginx/sites-enabled/yiitest-front

sudo echo 'server {
    set $web "/home/ruslan/www/Itroom/frontend/web/";
    set $index "index.php";
    set $charset "utf-8";
    set $fcp "unix:/var/run/php/php7.0-fpm.sock";

    listen  80;
    server_name yiitest-front.loc;
    root $web;

    charset $charset;

    location / {
        index  $index;
        try_files $uri $uri/ /$index?$args;
    }

    location ~ \.(js|css|png|jpg|gif|swf|ico|pdf)$ {
        try_files $uri = 404;
    }

    location ~ \.php {
        include fastcgi_params;

        fastcgi_split_path_info  ^(.+\.php)(.*)$;

        set $fsn /$index;
        if (-f $document_root$fastcgi_script_name){
            set $fsn $fastcgi_script_name;
        }

        fastcgi_pass   $fcp;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;

        fastcgi_param  SCRIPT_FILENAME  $document_root$fsn;
        fastcgi_param  PATH_INFO        $fastcgi_path_info;
        fastcgi_param  PATH_TRANSLATED  $document_root$fsn;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}' > /etc/nginx/sites-available/yiitest-front

sudo ln -s /etc/nginx/sites-available/yiitest-front /etc/nginx/sites-enabled/yiitest-front

rm -f /etc/nginx/sites-available/yiitest-back /etc/nginx/sites-enabled/yiitest-back

sudo echo 'server {
    set $web "/home/ruslan/www/Itroom/backend/web/";
    set $index "index.php";
    set $charset "utf-8";
    set $fcp "unix:/var/run/php/php7.0-fpm.sock";

    listen  80;
    server_name yiitest-back.loc;
    root $web;

    charset $charset;

    location / {
        index  $index;
        try_files $uri $uri/ /$index?$args;
    }

    location ~ \.(js|css|png|jpg|gif|swf|ico|pdf)$ {
        try_files $uri = 404;
    }

    location ~ \.php {
        include fastcgi_params;

        fastcgi_split_path_info  ^(.+\.php)(.*)$;

        set $fsn /$index;
        if (-f $document_root$fastcgi_script_name){
            set $fsn $fastcgi_script_name;
        }

        fastcgi_pass   $fcp;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;

        fastcgi_param  SCRIPT_FILENAME  $document_root$fsn;
        fastcgi_param  PATH_INFO        $fastcgi_path_info;
        fastcgi_param  PATH_TRANSLATED  $document_root$fsn;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}' > /etc/nginx/sites-available/yiitest-back

sudo ln -s /etc/nginx/sites-available/yiitest-back /etc/nginx/sites-enabled/yiitest-back

sudo service nginx restart
sudo service php7.0-fpm restart
sudo service mysql restart

echo '
----------------------------------------
DONE!
----------------------------------------
';

sudo rm -rf /home/ruslan/www/Itroom

echo '
----------------------------------------
Installing Yii2 Advanced Application Template
----------------------------------------
';

su - vagrant -c "curl -s https://getcomposer.org/installer | php"
rm -f /usr/local/bin/composer
cp composer.phar /usr/local/bin/composer
su - vagrant -c "composer global require "fxp/composer-asset-plugin:~1.1.1""
su - vagrant -c "mkdir -p /home/vagrant/.config/composer"
su - vagrant -c "composer config -g github-oauth.github.com 123c7bf88138c068f32de6aa6121657e21c9851c"

su - vagrant -c "composer create-project --no-interaction --prefer-dist yiisoft/yii2-app-advanced /home/ruslan/www/Itroom"

echo '
----------------------------------------
Configure application Yii2 Advanced
----------------------------------------
';

su - vagrant -c "cd /home/ruslan/www/Itroom && echo '0
yes' | php init"

sudo mysql -uroot -p1q2w3e4r -e 'CREATE DATABASE yii2advanced;'

sudo echo "<?php
return [
    'components' => [
        'db' => [
            'class' => 'yii\db\Connection',
            'dsn' => 'mysql:host=localhost;dbname=yii2advanced',
            'username' => 'root',
            'password' => '1q2w3e4r',
            'charset' => 'utf8',
            'enableSchemaCache' => true,
            'schemaCacheDuration' => 3600,
        ],
    ],
];
" > /home/ruslan/www/Itroom/common/config/main-local.php

su - vagrant -c "cd /home/ruslan/www/Itroom && php yii migrate --interactive=0"

echo '
----------------------------------------
Yii2 Advanced Template is Installed
----------------------------------------
';

echo '
----------------------------------------
Installing phpMyAdmin
----------------------------------------
';

rm -rf /home/ruslan/www/Itroom/phpmyadmin

su - vagrant -c "composer create-project --no-interaction --repository-url=https://www.phpmyadmin.net/packages.json --no-dev --prefer-dist phpmyadmin/phpmyadmin /home/ruslan/www/Itroom/phpmyadmin"

rm -f /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/phpmyadmin

sudo echo 'server {
    set $web "/home/ruslan/www/Itroom/phpmyadmin";
    set $index "index.php";
    set $charset "utf-8";
    set $fcp "unix:/var/run/php/php7.0-fpm.sock";

    listen  80;
    server_name phpmyadmin.loc;
    root $web;

    charset $charset;

    location / {
        index  $index;
        try_files $uri $uri/ /$index?$args;
    }

    location ~ \.(js|css|png|jpg|gif|swf|ico|pdf)$ {
        try_files $uri = 404;
    }

    location ~ \.php {
        include fastcgi_params;

        fastcgi_split_path_info  ^(.+\.php)(.*)$;

        set $fsn /$index;
        if (-f $document_root$fastcgi_script_name){
            set $fsn $fastcgi_script_name;
        }

        fastcgi_pass   $fcp;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;

        fastcgi_param  SCRIPT_FILENAME  $document_root$fsn;
        fastcgi_param  PATH_INFO        $fastcgi_path_info;
        fastcgi_param  PATH_TRANSLATED  $document_root$fsn;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}' > /etc/nginx/sites-available/phpmyadmin

sudo ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/phpmyadmin

sudo service nginx restart

echo '
----------------------------------------
phpMyAdmin Installed
----------------------------------------
';