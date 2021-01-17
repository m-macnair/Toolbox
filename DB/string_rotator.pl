
for my $x (
	qw/
	advantage
	audit
	bear
	cde
	cod
	cruises
	docs
	fcaudit
	geonames
	gnet
	hbp
	help
	holidays
	ihs
	inform
	kmt
	kmtbackup
	locations
	maxscale_schema

	odi
	packagedb
	parsers
	performance_schema
	requestids
	restore
	skidb
	suppliermigration
	tasks
	taxitransfers

	touradmin

	what
	wpseo
	wptraveltek
	xml
	zabbix /
  )
{
	next unless $x;
	print "perl /home/mmacnair/single_file_import.pl /home/mmacnair/dbs/general-8/$x.json /home/mmacnair/gits/ntt_sql_schemata/general/$x/$/";
}
