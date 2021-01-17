#!/usr/bin/perl
#ABSTRACT: Move all mp3 files in a folder into a temporary folder in name order, then swap with the original. Useful for dealing with Fat32 derived playing order on certain music players
our $VERSION = 'v1.0.1';

##~ DIGEST : 0c5bdaae2e15e4f3ad524e4cbc80812a
use strict;
use warnings;
main( @ARGV );

sub main {
	my ( $folder ) = @_;
	die "Must provide explicit folder" unless $folder && -d $folder;
	die "don't use `.` :|" if index( $folder, '.' ) != -1;
	$folder =~ s|/$||;
	my $temp_folder = "$folder\_tmp_" . time;

	my $type_string = '-name "*.mp3"';
	my @res         = split( $/, `find "$folder" -type f $type_string -maxdepth 1| sort ` );

	print `mkdir "$temp_folder"` unless -e $temp_folder;
	for ( @res ) {
		`mv "$_" "$temp_folder"`;
	}
	`mv "$folder" "$folder\_bak"`;
	`mv "$temp_folder" "$folder"`;

}

