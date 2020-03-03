#!/usr/bin/perl
use strict;
use warnings;
main( @ARGV );

sub main {
	my ( $bulk_args, $path_args );
	if ( scalar( @_ ) > 1 ) {
		require Toolbox::CombinedCLI;
		my $conf = Toolbox::CombinedCLI::array_config( [qw/ directory /], [qw/increment set /] );
		my $bulk_args = join( ' ', @_ );
		$path_args = "$conf->{directory}";
	} else {
		if ( @_ ) {
			$bulk_args = $path_args = shift;
		} else {
			$bulk_args = $path_args = './';
		}
	}

	print `perltidydir.sh $path_args`;
	print `fileversioncontrol_bulk $bulk_args`;
	print `zapdirectory.sh $path_args`;

}

