#!/usr/bin/perl
# ABSTRACT: lower snake case all file names at the first level of a directory and add a prefix space
our $VERSION = 'v0.0.4';

##~ DIGEST : e6c063561cf978231af121b127902e77

use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common

sub process {
	my ( $self, $path ) = @_;
	$self->sub_on_directory_files(
		sub {
			my ( $full_path ) = @_;

			return 1 unless -f $full_path;
			my ( $name, $dir, $suffix ) = $self->file_parse( $full_path );

			$name =~ s/^\s+|\s+$//g;
			$name =~ s/^_//g;
			$name =~ s/_$//g;
			$name = lc( $name );
			$name =~ s| |_|g;
			$name = " $name";

			my $new_path = "$dir/$name$suffix";
			$self->safe_cpf( $full_path, $new_path, {fatal => 0} );
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
	my ( $path ) = @_;

	$path ||= './';
	$self->process( $path );

}
