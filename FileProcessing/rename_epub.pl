use strict;
use warnings;
use Toolbox::FileSystem;
use EPUB::Parser;
use File::Copy qw/mv /;
use Try::Tiny;

main( @ARGV );

sub main {
	my ( $file ) = @_;

	Toolbox::FileSystem::checkfile( $file );

	try {
		my $ep = EPUB::Parser->new;
		$ep->load_file( {file_path => $file} );
	} catch {
		warn "\t[$file] is probably not an epub";
	};

	my $res = `exiftool -T -Title $file`;

	my $newname = "$res.epub";
	if ( -e $newname ) {
		warn "[$newname] already exists";
	} else {
		mv( $file, $newname ) or die $!;
	}

}
