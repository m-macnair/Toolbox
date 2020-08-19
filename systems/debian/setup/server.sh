#this might have saved me £100
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile


apt-get update
apt-get upgrade

apt-get install --assume-yes libcgi-pm-perl mariadb-server libcrypt-ssleay-perl libio-socket-ssl-perl   >> apt_install.log 
cpanm Data::UUID Moo  >> cpanm_install.log 
mysql_secure_installation

