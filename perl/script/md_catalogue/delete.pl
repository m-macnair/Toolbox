use strict;
use warnings;

package MK77;

#TIL use moo first does something weird to accessors - meant that the default methods always happend
use parent qw/
  Toolbox::Class::FileHashDB::Mk77
  /;
use Moo;

=head3 checkknown
	confirm things we know are there are still there
=cut
1;

package main;
use Toolbox::CombinedCLI;
use Data::Dumper;
main();

sub main {

	my $clv = Toolbox::CombinedCLI::get_config( [qw/dbfile /], [qw/ vocal /] );

	# 	warn Dumper($clv);
	my $mk77 = MK77->new( { dbfile => $clv->{dbfile} } );
	$mk77->dodeletes($clv);
	print "It is done. Move on!$/";

}
