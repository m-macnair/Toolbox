
use strict;
use warnings;

package Mk77;
use parent qw/
  Toolbox::Class::FileHashDB::Mk77
  Toolbox::Moo::Role::PID
  /;

=head3 checkknown
	confirm things we know are there are still there
=cut

sub dir_or_dirs {
	my ( $self, $c ) = @_;
	if ( $c->{dirs} ) {
		for my $dir ( @{$c->{dirs}} ) {
			$self->loaddirectory( $dir );
		}
	} else {
		$self->loaddirectory( $c->{dir} );
	}
}
1;

package main;
use Toolbox::CombinedCLI;
use Data::Dumper;
main();

# WARNING - need to make sure checknown and dir_or_dirs isn't disfunctional
sub main {

	my $clv = Toolbox::CombinedCLI::get_config( [ qw/dbfile /, [qw/ dirs dir /] ], [qw/ loadfirst initdb vocal markdeletes dodeletes /] );
	my $mk77 = Mk77->new( $clv );
	$mk77->startpid();
	my $loaded;

	#there was a reason I wanted this ; can't for the life of me remember what it was
	if ( $clv->{loadfirst} ) {

		$mk77->dir_or_dirs( $clv );
		$loaded = 1;
	}
	$mk77->checkknown( $clv );
	$mk77->dir_or_dirs( $clv ) unless $loaded;
	$mk77->md5all();

	if ( $clv->{markdeletes} ) {
		$mk77->initdirweight( $clv );
		$mk77->setonetrue( $clv );
		$mk77->setcheckedanddelete( $clv );
	}

	if ( $clv->{dodeletes} ) {
		$mk77->dodeletes( $clv );
	}

	$mk77->stoppid();
	print "It is done. Move on!$/";

}
