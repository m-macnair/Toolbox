find ./ -name "*.p[ml]" -type f -exec perl -cw {} \; -exec perltidy -b {} \;