ZPATH="$1";
if [ -d $ZPATH ]
then
	echo "Processing $ZPATH";
else
	ZPATH="./"
	echo "Processing $ZPATH";
fi
find $ZPATH -type f -a \( -iname "*.pm" -o -iname "*.pl" -o -iname "*.t" \) -exec perltidy -b {} \;