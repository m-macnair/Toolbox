#!/usr/bin/perl
use strict;
use warnings;
use Net::Wake;
main( @ARGV );

sub main {

	my ( $udpstr ) = @_;
	if ( $udpstr ) {
		my @udps = split( ',', $udpstr );
		for my $udp ( @udps ) {
			print "Waking $udp$/";
			Net::Wake::by_udp( undef, $udp );
		}
	} else {
		print "No udpstring provided$/" unless $udpstr;
	}

}
