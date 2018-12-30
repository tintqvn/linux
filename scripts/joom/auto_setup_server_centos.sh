#!/bin/bash
# Variables
$php56-ver=5.6.38
$php72-ver=7.2.12
$mariadb-ver=10.3.10
$nginx-ver=1.14.2

# Update and install require packet
yum -y update
yum -y install epel-release
yum -y install tmux wget net-tools httpd-tools git libxml2-devel pcre-devel openssl-devel curl-devel gd gd-devel icu libicu-devel libmcrypt libmcrypt-devel libtidy libtidy-devel libxslt libxslt-devel ncurses-devel uw-imap-devel gcc gcc-c++ libc-client-devel libtool-ltdl-devel ImageMagick ImageMagick-devel autoconf cmake bison unzip zip

# Add user
useradd tintq
useradd khanhle
useradd -M nginx
useradd -M mysql
usermod -s /sbin/nologin nginx
usermod -s /sbin/nologin mysql

# SE Linux
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

# Make Dir
mkdir /data/logs
mkdir /data/logs/php
mkdir /data/logs/mariadb
chown -R mysql:mysql mariadb
mkdir /data/logs/nginx
mkdir /data/scripts
mkdir /data/scripts/tmp
cd /data/scripts/tmp
wget https://github.com/tintqvn/WebServer/archive/master.zip
unzip master.zip
mkdir /data/sources
cd /data/sources

# Download and build PHP 5 and 7
# PHP 7
wget http://php.net/distributions/php-$php72-ver.tar.gz
wget http://php.net/distributions/php-$php56-ver.tar.gz
tar -xvf php-$php56-ver.tar.gz
tar -xvf php-$php72-ver.tar.gz
cd php-$php72-ver
cp /data/scripts/tmp/WebServer-master/PHP/build/setup_php.sh .
sed -i "s/php/php72/g" setup_php.sh
sh setup_php.sh && make && make install
cp php.ini-production /data/webserver/php72/lib/php.ini
cd /data/webserver/php72/etc/
cp php-fpm.conf.default php-fpm.conf
cd php-fpm.d/
cp www.conf.default www.conf
cp /data/scripts/tmp/WebServer-master/PHP/build/systemd.init /lib/systemd/system/php72-fpm.service
sed -i "s/php56/php72/g" /lib/systemd/system/php72-fpm.service
systemctl start php72-fpm
systemctl enable php72-fpm
# PHP 5
cd ./.. && cd php-$php56-ver
cp /data/scripts/tmp/WebServer-master/PHP/build/setup_php.sh .
sed -i "s/php/php56/g" setup_php.sh
sh setup_php.sh && make && make install
cp php.ini-production /data/webserver/php56/lib/php.ini
cd /data/webserver/php56/etc/
cp php-fpm.conf.default php-fpm.conf
cp /data/scripts/tmp/WebServer-master/PHP/build/systemd.init /lib/systemd/system/php56-fpm.service
systemctl enable php56-fpm

# Download and build MariaDB
cd /data/sources/
wget http://ossm.utm.my/mariadb//mariadb-$mariadb-ver/source/mariadb-$mariadb-ver.tar.gz
tar -xvf mariadb-$mariadb-ver.tar.gz
cd mariadb-$mariadb-ver
cp /data/scripts/tmp/WebServer-master/MariaDB/Build/setup_mariadb.sh .
sh setup_mariadb.sh && make && make install
cd /data/webserver/mariadb/
cp support-files/mysql.server /etc/init.d/mariadb
chmod +x /etc/init.d/mariadb
chkconfig mariadb on
./scripts/mysql_install_db --user=mysql --basedir=/data/webserver/mariadb --datadir=/data/webserver/mariadb/data
cp /data/scripts/tmp/WebServer-master/MariaDB/config/my.cnf .
chown -R mysql:root /data/webserver/mariadb/


# Download and install Nginx
cd /data/sources
wget http://nginx.org/download/nginx-$nginx-ver.tar.gz
tar -xvf nginx-$nginx-ver.tar.gz
cd nginx-$nginx-ver
cp /data/scripts/tmp/WebServer-master/Nginx/Build/setup_nginx.sh .
sh setup_nginx.sh && make & make install
cp /data/scripts/tmp/WebServer-master/Nginx/Build/nginx_systemd.sh /lib/systemd/system/nginx.service
systemctl start nginx
systemctl enable nginx
