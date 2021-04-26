!/bin/bash
#I make a point of splitting the OS disk into os and non_os to ease in recovery and transition
mkdir /mnt/non_os/
mount /dev/sda2 /mnt/non_os/
mv /var /mnt/non_os/
mv /home /mnt/non_os/
mv /tmp /mnt/non_os/
cd /
ln -s /mnt/non_os/tmp
ln -s /mnt/non_os/home
ln -s /mnt/non_os/var
