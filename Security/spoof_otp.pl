#!/usr/bin/perl
#ABSTRACT: script for providing OTP codes when provided with an original key
# DYZRQ4VIRFDAKITR
use strict;
use warnings;
use Auth::GoogleAuth;

main( @ARGV );

sub main {
	my ( $key ) = @_;
	die "Key required" unless $key;

	my $auth = Auth::GoogleAuth->new;
	$auth = Auth::GoogleAuth->new(
		{
			issuer => 'Gryphon Shafer',
			key_id => 'gryphon@cpan.org',
		}
	);
	my $code_1 = $auth->code( $key, time, 30 );
	print $code_1;
}
