#!/usr/bin/perl
use strict;
use JSON;
main( @ARGV );

sub main {
	my ( $file ) = @_;

	unless ( index( lc( $file ), '.json' ) != -1 ) {
		warn "\t[$file] is not a json file $/";
		exit;
	}
	processfile( @_ );

}

sub processfile {

	my $json = JSON->new();

	$json->canonical( 1 );
	my $buffer;
	open( my $ifh, '<:raw', $_[0] ) or die $!;
	while ( <$ifh> ) {
		$buffer .= $_;
	}
	close $ifh;
	my $href   = $json->decode( $buffer );
	my $string = $json->encode( $href );
	$string =~ s|   |\t|g;
	open( my $ofh, '>:raw', $_[0] ) or die $!;
	print $ofh $string;
	close $ofh;

}
