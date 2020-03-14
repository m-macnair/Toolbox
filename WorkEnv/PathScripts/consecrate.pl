#!/usr/bin/perl
use strict;
use warnings;
main( @ARGV );

sub main {
	my ( $bulk_args, $path_args );
	if ( scalar( @_ ) > 1 ) {
		require Toolbox::CombinedCLI;
		my $conf = Toolbox::CombinedCLI::get_config( [qw/ directory /], [qw/increment set /] );
		my $bulk_args = join( ' ', @_ );
		$path_args = "$conf->{directory}";
	} else {
		if ( @_ ) {
			$bulk_args = $path_args = shift;
		} else {
			$bulk_args = $path_args = './';
		}
	}

	system( "bulk_perl_file_prep.sh $bulk_args" );
	system( "zap_directory.sh $path_args" );

}

