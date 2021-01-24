#!/usr/bin/perl
our $VERSION = 'v1.0.1';

##~ DIGEST : beb30daf405867e77bb9efeea10d6d6d
use strict;
use warnings;
main( @ARGV );

sub main {

	my ( $bulk_args, $path_args );
	if ( scalar( @_ ) > 1 ) {
		require Toolbox::CombinedCLI;
		my $conf      = Toolbox::CombinedCLI::get_config( [qw/ directory /], [qw/increment set /] );
		my $bulk_args = join( ' ', @_ );
		$path_args = "$conf->{directory}";
	} else {
		if ( $_[0] ) {
			if ( -d $_[0] ) {
				$bulk_args = $path_args = shift;
			} elsif ( -f $_[0] ) {
				print "Consecrating single file$/";
				system( "perl_file_prep.sh $_[0]" );
				exit;
			}
		} else {
			$bulk_args = $path_args = './';
		}

	}

	system( "bulk_perl_file_prep.sh $bulk_args" );
	system( "zap_directory.sh $path_args" );

}
