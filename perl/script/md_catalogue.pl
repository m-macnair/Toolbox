use strict;
use warnings;

package Mk77;
use parent qw/Toolbox::Class::FileHashDB::Mk77/;

=head3 checkknown
	confirm things we know are there are still there
=cut

sub checkknown {
	my ( $self ) = @_;
	my $select_sth = $self->dbh->prepare( "
			select
			f.id as id,
			d.name as dir,
			f.name as file ,
			e.name as ext
		from
			file_list f 
			join dir_list d 
				on f.dir_id = d.id
			join ext_list e 
				on f.ext_id = e.id
			where deleted = null
	" );

	my $update_sth = $self->dbh->prepare( "
		update file_list set deleted = 1 where id = ?
	" );

	$select_sth->execute();
	while ( my $row = $select_sth->fetchrow_hashref() ) {
		my $path = "$row->{dir}/$row->{file}$row->{ext}";
		unless ( -f $path ) {
			$update_sth->execute( $row->{id} );
			$self->commitmaybe();
		}
	}
	$self->commithard();
}
1;

package main;
use Toolbox::CombinedCLI;
use Data::Dumper;
main();

sub main {

	my $clv = Toolbox::CombinedCLI::get_config( [qw/dbfile dir/], [qw/ loadfirst initdb /] );

	my $mk77 = Mk77->new( $clv );
	my $loaded;

	#there was a reason I wanted this ; can't for the life of me remember what it was
	if ( $clv->{loadfirst} ) {
		$mk77->loaddirectory( $clv->{dir} );
		$loaded = 1;
	}
	$mk77->checkknown();
	$mk77->loaddirectory( $clv->{dir} ) unless $loaded;
	$mk77->md5all();
	print "It is done. Move on!$/";

}
