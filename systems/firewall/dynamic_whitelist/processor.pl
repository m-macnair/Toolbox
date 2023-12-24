#!/usr/bin/perl
# ABSTRACT:
our $VERSION = 'v0.0.5';

##~ DIGEST : 091749da144e17f8fc5450a5591f9941

use strict;
use warnings;
use DBI;

main( @ARGV );

sub main {
	my ( $path, $wait, $repeat ) = @_;
	die "path to white list db not provided" unless $path;
	die "path to white list db invalid"      unless -f $path;
	$wait   ||= 10;
	$repeat ||= 5;

	my $dbh     = DBI->connect( 'dbi:SQLite:dbname=' . $path );
	my $get_sth = $dbh->prepare( "select * from white_list" );

	my $name = "in_host_dynamic_wl";
	my $IPT  = "/usr/sbin/iptables";
	print `$IPT -F $name`;
	print `$IPT -X $name`;
	print `$IPT -N $name`;
	while ( $repeat ) {
		print "Checking Dynamic Whitelist " . time . $/;
		print `$IPT -F $name`;

		$get_sth->execute();
		while ( my $row = $get_sth->fetchrow_hashref() ) {
			print `$IPT -A $name -s "$row->{ip_address}/32" -j ACCEPT`;
		}
		$repeat--;
		sleep( $wait );
	}

}
