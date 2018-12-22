#!/usr/bin/perl
use strict;
use warnings;
use Ryza::CombinedCLI;
use Data::Dumper;
main();

sub main {

	my $c = Ryza::CombinedCLI::array_config(
		[
			[

				qw/ functions prefixes suffixes /
			]
		],
		[qw/ headlevel noreturn explicitreturn doprefixfirst /]
	);

	$c->{headlevel} ||= 3;
	my $output;
	if ( $c->{functions} ) {
		for ( split( ' ', $c->{functions} ) ) {
			$output .= generate_sub( $_, $c );
		}
	} else {
		die( "Must provide both prefixes and suffixes" ) unless ( $c->{prefixes} and $c->{suffixes} );
		my @prefixes = sort( split( ' ', $c->{prefixes} ) );
		my @suffixes = sort( split( ' ', $c->{suffixes} ) );

		if ( $c->{doprefixfirst} ) {
			for my $prefix ( @prefixes ) {
				for my $suffix ( @suffixes ) {

					$output .= generate_sub( "$prefix\_$suffix", $c );
				}
			}
		} else {

			for my $suffix ( @suffixes ) {
				for my $prefix ( @prefixes ) {
					$output .= generate_sub( "$prefix\_$suffix", $c );
				}
			}
		}

	}
	print $output;
}

sub generate_sub {
	my ( $name, $c ) = @_;

	my $return = "=head$c->{headlevel} $name$/\t$/=cut$/sub $name {$/\t";
	if ( $c->{explicitreturn} ) {
		$return .= $c->{explicitreturn};
	} else {
		$return .= "return { pass => 1 }$/" unless $c->{noreturn};
	}
	$return .= "}$/";

	return $return; #return!

}

