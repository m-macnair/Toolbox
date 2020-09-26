#!/usr/bin/perl
use strict;
use warnings;
use Toolbox::CombinedCLI;
main();

sub main {

	my $clv = Toolbox::CombinedCLI::get_config(
		[
			qw/
			  path
			  /
		],
	);

	# TODO precompile re?
	my $search = {
		'sub' => {
			start => '^sub .* {$',
			end   => '^}$'
		}
	};
	my @mapkeys = keys( %{$search} );
	my $p       = {};

	# TODO tiering
	open( my $ifh, '<:utf8', $clv->{path} ) or die $!;
	while ( my $line = <$ifh> ) {
		if ( $p->{current} ) {

			#keep pushing and look for the closing token
		} else {
			my $match;
			for my $key ( @mapkeys ) {
				my ( $match ) = ( $line =~ m/($search->{$key}->{start})/ );
				last if $match;
			}
			if ( $match ) {
				$p->{current} = $match;
				push( $p->{elements}->{$match}, $line );
			} else {
				push( @{$p->{doc}}, $line );
			}
		}
	}

}
