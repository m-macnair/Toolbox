#!/usr/bin/perl
use strict;
use warnings;
use Toolbox::FileSystem;
use EPUB::Parser;
use File::Copy qw/mv /;
use Try::Tiny;

#rename gutenberg (etc) epubs from their catalogue number to title
main( @ARGV );

sub main {

	my ( $file ) = @_;
	Toolbox::FileSystem::checkfile( $file );
	try {
		my $ep = EPUB::Parser->new;
		$ep->load_file( {file_path => $file} );
	} catch {
		warn "\t[$file] is probably not an epub";
		exit;
	};
	my $res = `exiftool -T -Title "$file"`;
	$res =~ s|[ ]|_|g;
	$res =~ s|__|_|g;
	$res =~ s|[^A-Za-z0-9_]||g;
	my $newname = "$res.epub";
	if ( !$newname || $newname eq '.epub' ) {
		warn "[$file] produced an unusable name";
		exit;
	}
	if ( -e $newname ) {
		warn "[$newname] already exists";
	} else {
		mv( $file, $newname ) or die $!;
	}

}
