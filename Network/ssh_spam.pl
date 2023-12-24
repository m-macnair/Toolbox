#!/usr/bin/perl
# ABSTRACT:
our $VERSION = 'v0.0.2';

##~ DIGEST : 6e8417fef78d9a6a0762ee7d076e9b6f

use strict;
use warnings;
use Toolbox::CombinedCLI;
main();

sub main {
	my $clv = Toolbox::CombinedCLI::standard_config(
		{
			network     => undef,
			lower_limit => 1,
			upper_limit => 256,
		}
	);

	my ( $a, $b, $c ) = split( "\\.", $clv->{network} );
	my $current = $clv->{lower_limit};
	while ( $current != $clv->{upper_limit} ) {
		my $host = "$a.$b.$c.$current";
		print "$host...";
		print timed_execution( 1, sub { print `ssh $host` } );
		print $/;
		$current++;
	}
}

sub timed_execution {
	my ( $duration, $sub ) = @_;
	eval {
		local $SIG{ALRM} = sub { die "TIMEOUT" };
		alarm $duration;
		&$sub;
		alarm 0;
	};

	if ( $@ && $@ =~ m/TIMEOUT/ ) {

		# >:\
		return 0;
	} else {
		alarm 0;
		return $@;
	}
}
