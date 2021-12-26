#Debian itself
sh ../../shared_basic.sh
apt-get install --assume-yes sudo sysvinit-utils  >> ~/apt_install.log  
apt-get install --assume-yes iptables git net-tools  htop  rsync >> ~/apt_install.log  
