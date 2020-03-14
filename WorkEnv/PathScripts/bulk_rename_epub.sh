#!/usr/bin/bash
source _ze_path.source
find $ZPATH -name "*.epub" -maxdepth 1 -exec rename_epub.pl {} \;
