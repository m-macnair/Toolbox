use strict;
use warnings;

package Toolbox::DemandP;

# ABSTRACT: Do what I normally do for variable checks in a subroutine

require Exporter;
use Carp qw/confess/;
our @ISA = qw(Exporter);

our @EXPORT = qw/
  demand_p
  /;

=head3
	demandp($href,$arrer_of_required_keys);
	quick way to check a sub got what it was supposed to.
	Also supports [[qw/one of these/][qw/and those too/]] to match against overwrite configs and so on "If one of these values is present, move on"
=cut

sub demand_p {
	my ( $map, $list ) = @_;

	confess( "\$map is not a map, is instead : " . Dumper( $map ) )    unless ref( $map ) eq 'HASH';
	confess( "\$list is not a list, is instead : " . Dumper( $list ) ) unless ref( $list ) eq 'ARRAY';

	my $msg;
	CHECK: {
		for my $check ( @{$list} ) {
			THISCHECK: {
				my $ref = ref( $check );

				#"If one of these values is present, move on"
				if ( $ref eq 'ARRAY' ) {
					for my $subcheck ( @{$check} ) {
						if ( defined( $map->{$subcheck} ) ) {
							next THISCHECK;
						}
					}
					$msg = "None of [" . join( ',', @{$check} ) . "] provided in \$map";
					last CHECK;
				} elsif ( $ref ) {
					$msg = "Non SCALAR, Non ARRAY reference [$ref] passed in \$list";
					last CHECK;
				} else {
					unless ( $map->{$check} ) {
						$msg = "Required key [$check] missing in \$map";
						last CHECK;
					}
				}
			}
		}
	}
	if ( $msg ) {
		confess( "$msg - \$map :\n\t" . Dumper( $map ) );
	}
	return;
}

1;
