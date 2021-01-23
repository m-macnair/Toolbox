gate=1
while [  $gate ]
do
	
	sleep 1s
	gate=`ls /home/m/.pid_* 2>/dev/null`
	echo $gate;
done
echo "done!"