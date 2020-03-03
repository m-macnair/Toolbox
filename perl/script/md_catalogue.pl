use strict;
use warnings;

package Mk77;
use parent qw/Toolbox::Class::FileHashDB::Mk77/;

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

sub main {

	my $clv = Toolbox::CombinedCLI::get_config( [ qw/dbfile /, [qw/ dirs dir /] ], [qw/ loadfirst initdb /] );
	warn Dumper( $clv );
	my $mk77 = Mk77->new( $clv );
	my $loaded;

	#there was a reason I wanted this ; can't for the life of me remember what it was
	if ( $clv->{loadfirst} ) {

		$mk77->dir_or_dirs( $clv );
		$loaded = 1;
	}
	$mk77->checkknown();
	$mk77->dir_or_dirs( $clv ) unless $loaded;
	$mk77->md5all();
	print "It is done. Move on!$/";

}
