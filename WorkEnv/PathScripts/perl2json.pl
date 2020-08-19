#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Carp qw/croak confess cluck/;
use JSON;
main( @ARGV );

sub main {

	my ( $path ) = @_;
	die "file [$path] not found" unless -f $path;
	open( my $fh, '<:raw', $path ) or die "failed to open file [$path] : $!";
	my $buffer;
	while ( my $line = <$fh> ) {
		chomp( $line );
		$buffer .= $line;
	}
	close( $fh );
	my $json = JSON->new()->canonical( 1 )->pretty( 1 );
	my $v    = eval( $buffer );
	print $json->encode( $v ), $/;

}
