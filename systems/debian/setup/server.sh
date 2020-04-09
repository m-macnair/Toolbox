apt-get update
apt-get upgrade

apt-get install --assume-yes libcgi-pm-perl mariadb-server   >> apt_install.log 
cpanm Data::UUID Moo  >> cpanm_install.log 
mysql_secure_installation

