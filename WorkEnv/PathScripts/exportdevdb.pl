#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use Data::Dumper;
use Toolbox::JSON;
main(@ARGV);

sub main {
	my $def;
	
	for(qw/devconf.json devconfprivate.json/){
		my $path = "etc/$_";
		if (-f $path ){
			my $fdef = jsonloadfile($path);
			$def = {
				%{$def},
				%{$fdef}
			}
		}
	}
	unless (%{$def}){
		die "No usable definitions";
	}
	my $dbh = DBI->connect(
		$conf->{db}->{dsn},
		$conf->{db}->{user},
		$conf->{db}->{pass}
	) or die $DBI::errstr;
	my $tablesth = $dbh->prepare("show tables");
	$tablesth->execute();
	
	my $defsth = $dbh->prepare("show create table ?");
	while(my $tablerow = $tablesth->fetchrow_arrayref()){
		$defsth->excecute(@{$tablerow});
		my $createstmnt = $defsth->fetchrow_arrayref();
		print Dumper($createstmnt);
	}
}