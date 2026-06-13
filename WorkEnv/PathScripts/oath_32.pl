#!/usr/bin/perl
use strict;
use warnings;
main( @ARGV );

sub main {
	my ( $secret ) = @_;
	$secret =~ s/\s+//g;
	$secret = uc( $secret );

	my $last_code = '';
	while ( 1 ) {
		my $current_code = get_code( $secret );
		$current_code =~ s/^\s+|\s+$//g;
		unless ( $last_code eq $current_code ) {
			$last_code = $current_code;
			print "Current OTP: $current_code$/";
		}
		sleep( 1 );
	}
}

sub get_code {
	my ( $v ) = @_;
	return `oathtool --totp -b  $v 2>&1`;
}
