#!/usr/bin/perl
# ABSTRACT: run a regex on files, using *.* to apply to the file names when applicable
our $VERSION = 'v0.0.2';

##~ DIGEST : c57de4d1f775868767b0b9da5670b807

use strict;
use warnings;
require File::DosGlob;
use Data::Dumper;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw/
  Moo::GenericRole::FileSystem

  /;

sub process {
	my ( $self, $from, $to, $paths ) = @_;
	die "No path(s) provided" unless ref( $paths ) eq 'ARRAY';

	die "String not provided" unless $from;
	for my $path ( @{$paths} ) {
		die "Path not provided" unless $path;
		if ( -f $path ) {
			$self->check_file( $path, "Path to process" );
			my ( $file_path, $dir ) = $self->file_path_parts( $path );
			my $new_path = $file_path;
			$new_path =~ s|$from|$to|g;
			unless ( $file_path eq $new_path ) {
				$self->safe_mvf( $path, $new_path );
			}

		} elsif ( -d $path ) {
			$self->check_dir( $path, "Path to process" );

			#this worries me
			my $new_path = $path;
			$new_path =~ s|$from|$to|g;
			if ( $path eq $new_path ) {

				#de nada
			} else {

				#ferociously dangerous - need a better answer
				die "$new_path already exists " if -d $new_path;
				`mv "$path" "$new_path"`;
			}

		} else {
			die "$path is not a file or a directory - not processing";
		}

	}
}
1;

package main;

main();

sub main {
	my $self = Obj->new();
	my ( $from, $to, $paths ) = $self->splice_glob_argv( 2 );
	$self->process( $from, $to, $paths );

}
