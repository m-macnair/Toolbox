use strict;
use warnings;

package Toolbox::FileIO::CSV;

#ABSTRACT : Toolbox::CSV mk2

our $VERSION = 'v1.0.1';

##~ DIGEST : 7baaac4fbab5a70a6ce7a54eb6ebf023
our $CSV;
use Text::CSV;

# do something on csv rows that aren't commented out until something returns falsey
sub suboncsv {

	my ( $sub, $path ) = @_;

	die "[$path] not found" unless ( -e $path );
	die "sub isn't a code reference" unless ( ref( $sub ) eq 'CODE' );

	open( my $ifh, "<:encoding(UTF-8)", $path )
	  or die "Failed to open [$path] : $!";
	my $csv = getcsv();
	while ( my $colref = $csv->getline( $ifh ) ) {
		if ( index( $colref->[0], '#' ) == 0 ) {
			next;
		}
		last unless &$sub( $colref );
	}

	close( $ifh ) or die "Failed to close [$path] : $!";

}

sub getcsv {
	unless ( $CSV ) {
		$CSV = Text::CSV->new( {binary => 1, eol => "\n"} ) # should set binary attribute.
		  or die "Cannot use CSV: " . Text::CSV->error_diag();
	}
	return $CSV;
}

1;
