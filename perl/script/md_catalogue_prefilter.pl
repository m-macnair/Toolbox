use strict;
use warnings;

package MK77;

#TIL use moo first does something weird to accessors - meant that the default methods always happend
use parent qw/
  Toolbox::Class::FileHashDB::Mk77
  /;
use Moo;

STHS: {
	for my $pair (

		#FILE
		[ 'sth_get_hashes',  'select distinct(md5) from file_list where md5 is not null' ],
		[ 'sth_delete_hash', "update file_list set todelete = 1 where md5 = ?" ],
	  )
	{
		has $pair->[0] => (
			is      => 'rw',
			lazy    => 1,
			default => sub { $_[0]->dbh->prepare( $pair->[1] ) }
		);
	}
}

=head3 checkknown
	confirm things we know are there are still there
=cut

1;

package main;
use Toolbox::CombinedCLI;
use Data::Dumper;
main();

sub main {

	my $clv = Toolbox::CombinedCLI::get_config( [qw/rawdb filterdbs /], [qw/ dodeletes /] );

	# 	warn Dumper($clv);
	my $mk77_raw = MK77->new(
		{
			dbfile => $clv->{rawdb}
		}
	);

	my $filterfiles;
	if ( ref( $clv->{filterdbs} ) eq 'ARRAY' ) {
		$filterfiles = $clv->{filterdbs};
	} else {
		$filterfiles = [ $clv->{filterdbs} ];
	}

	for my $filterdb ( @{$filterfiles} ) {
		warn $filterdb;
		my $mk77_filter = MK77->new(
			{
				dbfile => $filterdb
			}
		);

		$mk77_filter->sth_get_hashes()->execute();
		while ( my $filter_row = $mk77_filter->sth_get_hashes()->fetchrow_arrayref() ) {
			$mk77_raw->sth_delete_hash->execute( $filter_row->[0] );
			$mk77_raw->commitmaybe();
		}
		$mk77_filter->dbh->disconnect();
		$mk77_raw->commithard();
	}
	if ( $clv->{dodeletes} ) {
		$mk77_raw->dodeletes();
	}

	print "It is done. Move on!$/";

}
