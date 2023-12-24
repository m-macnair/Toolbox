#!/usr/bin/perl
# ABSTRACT: given a string, remove the string and lower snake case all file names at the first level of a directory
our $VERSION = 'v0.0.4';

##~ DIGEST : 319c168134d0b83788ef718fd6ec7cc7

use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common

sub process {
	my ( $self, $string, $path ) = @_;
	$self->sub_on_directory_files(
		sub {
			my ( $full_path ) = @_;

			return 1 unless -f $full_path;
			my ( $name, $dir, $suffix ) = $self->file_parse( $full_path );

			$name =~ s/$string//g if $string;
			$name =~ s/^\s+|\s+$//g;
			$name =~ s/^_//g;
			$name =~ s/_$//g;
			$name = lc( $name );
			my $new_path = ( $self->percent_file( $self->snake_file( "$dir/$name$suffix" ) ) );

			$self->safe_mvf( $full_path, $new_path, {fatal => 0} );
			return 1;

		},
		$path
	);
}
1;

package main;

main( @ARGV );

sub main {
	my $self = Obj->new();
	my ( $string, $path ) = @_;

	$path ||= './';
	$self->process( $string, $path );

}
