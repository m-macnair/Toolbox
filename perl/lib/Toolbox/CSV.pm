use strict;
use warnings;

package Toolbox::CSV;
use base "Toolbox::SimpleClass";

sub suboncsv {

	my ( $self, $path, $sub ) = @_;

	die "[$path] not found" unless ( -e $path );
	die "sub isn't a code reference" unless ( ref( $sub ) eq 'CODE' );

	open( my $ifh, "<:encoding(UTF-8)", $path ) or die "Failed to open [$path] : $!";
	my $csv = $self->getcsv();
	while ( my $colref = $csv->getline( $ifh ) ) {
		if ( index( $colref->[0], '#' ) == 0 ) {
			next;
		}
		&$sub( $colref );
	}

	close( $ifh ) or die "Failed to close [$path] : $!";

}

sub getcsv {
	my ( $self ) = @_;
	unless ( $self->{CSV} ) {
		require Text::CSV;
		$self->{CSV} = Text::CSV->new( {binary => 1, eol => "\n"} ) # should set binary attribute.
		  or die "Cannot use CSV: " . Text::CSV->error_diag();
	}
	return $self->{CSV};
}

sub hreftocsv {
	my ( $self, $href, $filename, $conf ) = @_;

	my $columns = $self->{instance}->{'Toolbox::CSV'}->{$filename}->{columns};
	unless ( @$columns ) {
		@$columns = ( sort( keys( $href ) ) );
	}

	for ( @$columns ) {

	}

}

1;
