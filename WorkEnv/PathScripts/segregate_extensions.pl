#!/usr/bin/perl
use strict;
use warnings;
use File::Find::Rule;
use Toolbox::FileSystem;
use File::Basename;
use Data::Dumper;
main( @ARGV );

sub main {

	my ( $dir ) = @_;
	$dir ||= './';
	use File::Find::Rule;

	# find all the subdirectories of a given directory
	my @files = File::Find::Rule->file->maxdepth( 1 )->in( $dir );
	my $types = {};
	for my $file ( @files ) {
		my ( $name, $path, $suffix ) = fileparse( $file, qr/\.[^.]*/ );
		next unless $name;  #suggests a hidden file;
		next unless $suffix;
		$suffix = lc( $suffix );
		push( @{$types->{$suffix}}, Toolbox::FileSystem::abspath( $file ) );
	}
	for my $suffix ( keys( %{$types} ) ) {
		my $segdir = $suffix;
		$segdir =~ s/^\.//g;
		$segdir = Toolbox::FileSystem::abspath( "$dir/$segdir" );
		unless ( -e $segdir ) {
			mkdir( $segdir );
		}
		for my $file ( @{$types->{$suffix}} ) {
			Toolbox::FileSystem::safemvf( $file, $segdir );
		}
	}

}
