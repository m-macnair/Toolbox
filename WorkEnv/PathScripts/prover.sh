clear
if[ -d $1 ]
	prove -I $1 -l -r t
else
	prove -l -r t
fi 