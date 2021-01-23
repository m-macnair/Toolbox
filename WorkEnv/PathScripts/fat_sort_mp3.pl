#!/usr/bin/perl
#ABSTRACT: Move all mp3 files in a folder into a temporary folder in name order, then swap with the original. Useful for dealing with Fat32 derived playing order on certain music players
our $VERSION = 'v1.0.2';

##~ DIGEST : 1fcd9929c0e2e313e843a79c972a3206
use strict;
use warnings;
main( @ARGV );

sub main {
	require Moo::GenericRole::CombinedCLI;
	my ( $paths ) = Moo::GenericRole::CombinedCLI::splice_glob_argv( 0 );
	for my $path ( @{$paths} ) {

		die "Must provide explicit folder" unless $path && -d $path;
		die "don't use `.` :|" if index( $path, '.' ) != -1;
		$path =~ s|/$||;
		my $temp_folder = "$path\_tmp_" . time;

		my $type_string = '-name "*.mp3"';
		my @res         = split( $/, `find "$path" -type f $type_string -maxdepth 1| sort ` );

		print `mkdir "$temp_folder"` unless -e $temp_folder;
		for ( @res ) {
			`mv "$_" "$temp_folder"`;
		}
	}

}

