#DOUGAN SPECIFIC
perl -pi -e 's|http://archive.raspberrypi.org/debian/|http://beregost.lan:3142/archive.raspberrypi.org/debian/|' /etc/apt/sources.list.d/raspi.list
perl -pi -e 's|http://raspbian.raspberrypi.org/raspbian/|http://beregost.lan:3142/raspbian.raspberrypi.org/raspbian/|' /etc/apt/sources.list.d/raspi.list
