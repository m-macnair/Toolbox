#!/bin/bash
source _ze_path.source
echo "Running perl_file_prep.sh on all perl assets - this will take a while"
find $ZEPATH -type f -a \( -iname "*.pm" -o -iname "*.pl" -o -iname "*.t" \) -exec perl_file_prep.sh {} \;