#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi
STARTAPACHE='/etc/init.d/apache2 restart'
STARTXBT='./xbt_tracker'
STARTMEMCACHED='/etc/init.d/memcached restart'
user='u232'
db='u232'
dbhost='localhost'
blank=''
announce='http:\/\/'
function randomString {
		local myStrLength=8;
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
announce=$announce$baseurl
apt-get update
apt-get upgrade
updatedb
apt-get install software-properties-common
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository 'deb http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.1/ubuntu trusty main'
apt-get update
apt-get install mariadb-server libmariadbclient-dev apache2 memcached libpcre3 libpcre3-dev cmake g++ libboost-date-time-dev libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev make subversion zlib1g-dev unzip libssl-dev php5 libapache2-mod-php5 php5-mysql php5-curl php5-gd php5-idn php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-mhash php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl php5-json php5-cgi php5-dev phpmyadmin
mysql_secure_installation
$STARTAPACHE
cd ~
echo 'Please enter your root password for MYSQL when asked'
echo "create database $db;
create user $user;
grant all on $db.* to '$user'@'localhost'identified by '$pass';" > blah.sql
mysql -u root -p < blah.sql
rm blah.sql
wget https://github.com/Bigjoos/U-232-V4/archive/master.tar.gz
tar xfz master.tar.gz
cd U-232-V4-master
tar -zxf pic.tar.gz
tar -zxf GeoIP.tar.gz
tar -zxf javairc.tar.gz
tar xfz Log_Viewer.tar.gz
cd /var
mkdir bucket
mkdir bucket/avatar
cd bucket
cp ~/U-232-V4-master/torrents/.htaccess .
cp ~/U-232-V4-master/torrents/index.* .
cd avatar
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
chmod 777 /var/www/install
chmod 777 /var/www/install/extra
chmod 777 /var/www/sqlerr_logs/
chmod 777 /var/www/torrents
sed 's/#mysql_user/'$user'/' /var/www/install/extra/config.xbtsample.php > /var/www/include/config.php
sed -i 's/#mysql_pass/'$pass'/' /var/www/include/config.php
sed -i 's/#mysql_db/'$db'/' /var/www/include/config.php
sed -i 's/#mysql_host/'$dbhost'/' /var/www/include/config.php
sed -i 's/#cookie_prefix/'$blank'/' /var/www/include/config.php
sed -i 's/#cookie_path/'$blank'/' /var/www/include/config.php
sed -i 's/#cookie_domain/'$blank'/' /var/www/include/config.php
sed -i 's/#domain/'$blank'/' /var/www/include/config.php
sed -i 's/#announce_urls/'$announce'/' /var/www/include/config.php
sed -i 's/#announce_https/'$blank'/' /var/www/include/config.php
sed -i 's/#site_email/'$email'/' /var/www/include/config.php
sed -i 's/#site_name/'$name'/' /var/www/include/config.php
sed 's/#mysql_user/'$user'/' /var/www/install/extra/ann_config.xbtsample.php > /var/www/include/ann_config.php
sed -i 's/#mysql_pass/'$pass'/' /var/www/include/ann_config.php
sed -i 's/#mysql_db/'$db'/' /var/www/include/ann_config.php
sed -i 's/#mysql_host/'$dbhost'/' /var/www/include/ann_config.php
sed -i 's/#baseurl/'$baseurl'/' /var/www/include/ann_config.php
mysql -u $user -p$pass $db < /var/www/install/extra/install.xbt.sql
mv /var/www/install /var/www/.install

cd ~
svn co http://xbt.googlecode.com/svn/trunk/xbt/misc xbt/misc
svn co http://xbt.googlecode.com/svn/trunk/xbt/Tracker xbt/Tracker
sleep 2
cp -R /var/www/XBT/{server.cpp,server.h,xbt_tracker.conf}  /root/xbt/Tracker/
cd /root/xbt/Tracker/
./make.sh
sed -i 's/mysql_user=/mysql_user='$user'/' /root/xbt/Tracker/xbt_tracker.conf
sed -i 's/mysql_password=/mysql_password='$pass'/' /root/xbt/Tracker/xbt_tracker.conf
sed -i 's/mysql_database=/mysql_database='$db'/' /root/xbt/Tracker/xbt_tracker.conf
sed -i 's/mysql_host=/mysql_host'$dbhost'/' /root/xbt/Tracker/xbt_tracker.conf
nano /root/xbt/Tracker/xbt_tracker.conf
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

	 if [ $checkxbt -le 0 ]

	then 

	$STARTXBT

		if ps ax | grep -v grep | grep $SERVICE >/dev/null

	then

		echo "$SERVICE service is now restarted, everything is fine"

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

	 if [ $chkmem -le 0 ]

	then 

	$STARTMEMCACHED

		if ps ax | grep -v grep | grep $SERVICE >/dev/null

	then

		echo "$SERVICE service is now restarted, everything is fine"

		fi

	fi
		
fi

#####CHECK APACHE2###########
SERVICE='apache2'

if ps ax | grep -v grep | grep $SERVICE > /dev/null

then

    echo "$SERVICE service running, everything is fine" 

else

    echo "$SERVICE is not running, restarting $SERVICE" 

        checkapache=`ps ax | grep -v grep | grep -c apache2`

                if [ $checkapache -le 0 ]

                then

                        $STARTAPACHE

                                if ps ax | grep -v grep | grep $SERVICE > /dev/null

                then

                            echo "$SERVICE service is now restarted, everything is fine" 

                                fi

                fi

fi
cd /etc/apache2/sites-enabled
nano 000-default.conf
$STARTAPACHE
