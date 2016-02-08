#!/bin/bash
if [[ $EUID != 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi
STARTNGINX='service nginx restart'
STARTXBT='./xbt_tracker'
STARTMEMCACHED='service memcached restart'
STARTPHPFPM='service php7.0-fpm restart'
user='u232'
db='u232'
dbhost='localhost'
blank=''
announcebase='http:\/\/'
httpsannouncebase='https:\/\/'
announce2='\/announce.php'
xbt='xbt'
function randomString {
        local myStrLength=16;
        local mySeedNumber=$$`date +%N`;
        local myRandomString=$( echo $mySeedNumber | md5sum | md5sum );
        myRandomResult="${myRandomString:2:myStrLength}"
}

randomString;
pass=$myRandomResult
clear

echo 'This will install the absolute minimum requirements to get the site running'
echo -n "Enter the site's base url (with no http(s):// or www): "
read baseurl
echo -n "Enter the site's name: "
read name
echo -n "Enter the site's email: "
read email
echo -n "Do you want to enable SSL (y/n): "
read ssl
announce=$announcebase$baseurl$announce2
httpsannounce=$httpsannouncebase$baseurl$announce2
apt-get -y update
apt-get -y upgrade
apt-get -y install lsb-release
codename=$(lsb_release -a | grep Codename | awk '{ printf $2 }')

case $codename in
	"jessie")
        ;;
    *)
        echo `tput setaf 1``tput bold`"This OS is not yet supported! (EXITING)"`tput sgr0`
        echo
        exit 1
        ;;
esac
if [[ $xbt = 'xbt' ]]; then
    echo -n "Do you want to run XBT tracker or php? (xbt/php)"
    read xbt
fi
case $xbt in
    'xbt')
		extras='libmariadbclient-dev libpcre3 libpcre3-dev cmake g++ libboost-date-time-dev libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev make subversion zlib1g-dev'
		announce=$announcebase$baseurl
        ;;
    'php')
        ;;
    *)
        echo`tput setaf 1``tput bold`"You did not enter a valid tracker type (EXITING)"`tput sgr0`
        echo
        exit 1
        ;;
esac

apt-get -y install software-properties-common
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
wget https://www.dotdeb.org/dotdeb.gpg
apt-key add dotdeb.gpg
rm dotdeb.gpg
add-apt-repository "deb [arch=amd64,i386] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.1/debian jessie main"
add-apt-repository "deb http://packages.dotdeb.org jessie all"

apt-get -y update
apt-get -y install mariadb-server memcached unzip libssl-dev php7.0 php7.0-mysql php7.0-json locate php7.0-fpm nginx php7.0-memcached $extras

updatedb
mysql_secure_installation
cd /etc/nginx/sites-enabled
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.0/fpm/php.ini
sed -i "s/user = www-data/user = www-data/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = www-data/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/;listen\.owner.*/listen.owner = www-data/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/;listen\.group.*/listen.group = www-data/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0660/" /etc/php/7.0/fpm/pool.d/www.conf # This passage in not required normally
echo "memcached.serializer = 'php'" >> /etc/php/7.0/fpm/php.ini
rm default*
cd ../sites-available
rm default*
echo "server {
    listen 80 default_server;

    root /var/www;
    index index.html index.htm index.php;

    server_name $baseurl;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;

        # With php7.0-fpm:
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;

        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}" > /etc/nginx/sites-available/default
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled
$STARTNGINX
cd ~
echo 'Please enter your root password for MYSQL when asked'
echo "create database $db;
grant all on $db.* to '$user'@'localhost'identified by '$pass';" > blah.sql
mysql -u root -p < blah.sql
rm blah.sql
wget https://github.com/Bigjoos/U-232-V4/archive/master.tar.gz
tar xfz master.tar.gz
cd U-232-V4-master
tar xfz pic.tar.gz
tar xfz GeoIP.tar.gz
tar xfz javairc.tar.gz
tar xfz Log_Viewer.tar.gz
cd /var
mkdir -p /var/bucket/avatar
cd /var/bucket
cp ~/U-232-V4-master/torrents/.htaccess .
cp ~/U-232-V4-master/torrents/index.* .
cd /var/bucket/avatar
cp ~/U-232-V4-master/torrents/.htaccess .
cp ~/U-232-V4-master/torrents/index.* .
cd ~
chmod -R 777 /var/bucket
cp -ar ~/U-232-V4-master/* /var/www
chmod -R 777 /var/www/cache
chmod 777 /var/www/dir_list
chmod 777 /var/www/uploads
chmod 777 /var/www/uploadsub
chmod 777 /var/www/imdb
chmod 777 /var/www/imdb/cache
chmod 777 /var/www/imdb/images
chmod 777 /var/www/include
chmod 777 /var/www/include/backup
chmod 777 /var/www/include/settings
echo > /var/www/include/settings/settings.txt
chmod 777 /var/www/include/settings/settings.txt
chmod 777 /var/www/sqlerr_logs/
chmod 777 /var/www/torrents
rm /var/www/include/class/class_cache.php
wget https://gitlab.open-scene.net/whocares/u232-v4-xbt-mariadb-php5/raw/master/class_cache.php -O /var/www/include/class/class_cache.php
configfile='/var/www/install/extra/config.'$xbt'sample.php'
sed 's/#mysql_user/'$user'/' $configfile > /var/www/include/config.php
sed -i 's/#mysql_pass/'$pass'/' /var/www/include/config.php
sed -i 's/#mysql_db/'$db'/' /var/www/include/config.php
sed -i 's/#mysql_host/'$dbhost'/' /var/www/include/config.php
sed -i 's/#cookie_prefix/'$blank'/' /var/www/include/config.php
sed -i 's/#cookie_path/'$blank'/' /var/www/include/config.php
sed -i 's/#cookie_domain/'$blank'/' /var/www/include/config.php
sed -i 's/#domain/'$blank'/' /var/www/include/config.php
sed -i 's/#announce_urls/'$announce'/' /var/www/include/config.php
sed -i 's/#announce_https/'$httpsannounce'/' /var/www/include/config.php
sed -i 's/#site_email/'$email'/' /var/www/include/config.php
sed -i 's/#site_name/'"$name"'/' /var/www/include/config.php
annconfigfile='/var/www/install/extra/ann_config.'$xbt'sample.php'
sed 's/#mysql_user/'$user'/' $annconfigfile > /var/www/include/ann_config.php
sed -i 's/#mysql_pass/'$pass'/' /var/www/include/ann_config.php
sed -i 's/#mysql_db/'$db'/' /var/www/include/ann_config.php
sed -i 's/#mysql_host/'$dbhost'/' /var/www/include/ann_config.php
sed -i 's/#baseurl/'$baseurl'/' /var/www/include/ann_config.php
mysqlfile='/var/www/install/extra/install.'$xbt'.sql'
mysql -u $user -p$pass $db < $mysqlfile
mv /var/www/install /var/www/.install
rm /var/www/index.html
chown -R www-data:www-data /var/www
chown -R www-data:www-data /var/bucket

cd ~
if [ ! -f /etc/php/mods-available/memcached.ini ]; then
echo "; configuration for php memcached module
; priority=20
extension=memcached.so" > /etc/php/mods-available/memcached.ini
fi
if [ ! -f /etc/php/7.0/fpm/conf.d/20-memcached.ini ]; then
ln -s /etc/php/mods-available/memcached.ini /etc/php/7.0/fpm/conf.d/20-memcached.ini
fi
if [ ! -f /etc/php/7.0/cli/conf.d/20-memcached.ini ]; then
ln -s /etc/php/mods-available/memcached.ini /etc/php/7.0/cli/conf.d/20-memcached.ini
fi
$STARTPHPFPM
cd ~

if [[ $ssl = 'y' ]]; then
	apt-get install -y openssl
	mkdir -p /etc/nginx/ssl/cert
	mkdir -p /etc/nginx/ssl/private
	openssl genrsa -des3 -out $baseurl.key 2048
	openssl req -new -key $baseurl.key -out $baseurl.csr
	cp $baseurl.key $baseurl.key.org
	openssl rsa -in $baseurl.key.org -out $baseurl.key
	rm $baseurl.key.org
	openssl x509 -req -days 365 -in $baseurl.csr -signkey $baseurl.key -out $baseurl.crt
	cp $baseurl.crt /etc/nginx/ssl/cert/
	cp $baseurl.key /etc/nginx/ssl/private/
	echo "server {
    listen   443;
    ssl on;
    ssl_certificate /etc/nginx/ssl/cert/$baseurl.crt;
    ssl_certificate_key /etc/nginx/ssl/private/$baseurl.key;
    server_name $baseurl;
    root /var/www;
    index index.html index.htm index.php;

    server_name $baseurl;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;

        # With php7.0-fpm:
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;

        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}" > /etc/nginx/sites-available/$baseurl-ssl
ln -s /etc/nginx/sites-available/$baseurl-ssl /etc/nginx/sites-enabled
fi

$STARTNGINX

if [[ $xbt = 'xbt' ]]; then
    svn co -r 2466 http://xbt.googlecode.com/svn/trunk/xbt/misc xbt/misc
    svn co -r 2466 http://xbt.googlecode.com/svn/trunk/xbt/Tracker xbt/Tracker
    sleep 2
    cp -R /var/www/XBT/{server.cpp,server.h,xbt_tracker.conf}  /root/xbt/Tracker/
    cd /root/xbt/Tracker/
    ./make.sh
    sed -i 's/mysql_user=/mysql_user='$user'/' /root/xbt/Tracker/xbt_tracker.conf
    sed -i 's/mysql_password=/mysql_password='$pass'/' /root/xbt/Tracker/xbt_tracker.conf
    sed -i 's/mysql_database=/mysql_database='$db'/' /root/xbt/Tracker/xbt_tracker.conf
    sed -i 's/mysql_host=/mysql_host'$dbhost'/' /root/xbt/Tracker/xbt_tracker.conf
    cd /root/xbt/Tracker
    ./xbt_tracker
    cd /root/xbt/Tracker/ 
    SERVICE='xbt_tracker'
     if  ps ax | grep -v grep | grep $SERVICE > /dev/null
    then
        echo "$SERVICE service running, everything is fine"
    else
        echo "$SERVICE is not running, restarting $SERVICE" 

         checkxbt=`ps ax | grep -v grep | grep -c xbt_tracker`

         if [ $checkxbt <= 0 ]

        then 

        $STARTXBT

            if ps ax | grep -v grep | grep $SERVICE >/dev/null

        then

            echo "$SERVICE service is now restarted, everything is fine"

            fi

        fi
            
    fi
fi
######CHECK MEMCACHED######
SERVICE='memcached'

 if  ps ax | grep -v grep | grep $SERVICE > /dev/null
then
    echo "$SERVICE service running, everything is fine"
else
    echo "$SERVICE is not running, restarting $SERVICE" 

     chkmem=`ps ax | grep -v grep | grep -c memcached`

     if [ $chkmem <= 0 ]

    then 

    $STARTMEMCACHED

        if ps ax | grep -v grep | grep $SERVICE >/dev/null

    then

        echo "$SERVICE service is now restarted, everything is fine"

        fi

    fi
        
fi
######CHECK nginx######
SERVICE='nginx'

 if  ps ax | grep -v grep | grep $SERVICE > /dev/null
then
    echo "$SERVICE service running, everything is fine"
else
    echo "$SERVICE is not running, restarting $SERVICE" 

     chkmem=`ps ax | grep -v grep | grep -c memcached`

     if [ $chkmem <= 0 ]

    then 

    $STARTNGINX

        if ps ax | grep -v grep | grep $SERVICE >/dev/null

    then

        echo "$SERVICE service is now restarted, everything is fine"

        fi

    fi
        
fi
######CHECK php-fpm######
SERVICE='php-fpm'

 if  ps ax | grep -v grep | grep $SERVICE > /dev/null
then
    echo "$SERVICE service running, everything is fine"
else
    echo "$SERVICE is not running, restarting $SERVICE" 

     chkmem=`ps ax | grep -v grep | grep -c memcached`

     if [ $chkmem <= 0 ]

    then 

    $STARTPHPFPM

        if ps ax | grep -v grep | grep $SERVICE >/dev/null

    then

        echo "$SERVICE service is now restarted, everything is fine"

        fi

    fi
        
fi