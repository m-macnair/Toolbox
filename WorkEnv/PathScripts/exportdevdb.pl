#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use Data::Dumper;
use Toolbox::JSON;
main( @ARGV );

sub main {
	my $conf = {};

	for ( qw/devconf.json devconfprivate.json/ ) {
		my $path = "./etc/$_";

		if ( -f $path ) {
			my $fdef = jsonloadfile( $path ) || {};

			$conf = {%{$conf}, %{$fdef}};
		}
	}
	unless ( %{$conf} ) {
		die "No usable definitions";
	}
	my $dbh = DBI->connect( $conf->{db}->{dsn}, $conf->{db}->{user}, $conf->{db}->{pass}, {RaiseError => 1} ) or die $DBI::errstr;

	my @tables = $dbh->tables();

	for ( @tables ) {

		my $row = $dbh->selectall_arrayref( "show create table $_ " )->[0];

		my $ofn = "etc/schema/$row->[0].sql";
		open( my $ofh, '>', $ofn ) or die "Unable to open [$ofn] : $!";
		$row->[1] =~ s/\) ENGINE.*/\)/;

		print $ofh $row->[1];
		close( $ofh ) or die "Unable to close [$ofn] : $!";
		`git add $ofn`;
	}

}
